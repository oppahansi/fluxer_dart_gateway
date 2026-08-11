import 'dart:async';
import 'dart:convert';

import 'package:fluxer_utils/fluxer_utils.dart';

import 'connection_state.dart';
import 'gateway_event.dart';
import 'gateway_transport.dart';
import 'heartbeat_manager.dart';
import 'opcodes.dart';
import 'web_socket_gateway_transport.dart';

/// The gateway orchestrator: owns the connection state machine, drives the
/// HELLO → IDENTIFY/RESUME → heartbeat → DISPATCH handshake, and decides
/// when to reconnect.
///
/// Talks to the outside world only through [GatewayTransport][] (Adapter
/// pattern), so it's fully unit-testable without a real socket — see
/// `test/gateway_connection_test.dart` for a fake transport driving it
/// through the happy path, RESUME, and reconnect scenarios.
///
/// [GatewayTransport]: package:fluxer_gateway/src/gateway_transport.dart
class GatewayConnection {
  GatewayConnection({
    required this.gatewayUrl,
    required this.token,
    this.shardId,
    this.shardCount,
    GatewayTransport Function(Uri)? transportFactory,
    Map<String, dynamic>? properties,
    Logger? logger,
    RetryPolicy? reconnectPolicy,
  }) : assert(
         (shardId == null) == (shardCount == null),
         'shardId and shardCount must be given together',
       ),
       _transportFactory =
           transportFactory ?? WebSocketGatewayTransport.connect,
       properties =
           properties ??
           const {
             'os': 'dart',
             'browser': 'fluxer.dart',
             'device': 'fluxer.dart',
           },
       logger = logger ?? const NoopLogger(),
       reconnectPolicy = reconnectPolicy ?? ExponentialBackoffRetryPolicy();

  final Uri gatewayUrl;
  final String token;
  final Map<String, dynamic> properties;
  final Logger logger;
  final RetryPolicy reconnectPolicy;

  /// This shard's index and the total shard count sent as IDENTIFY's
  /// `shard: [shardId, shardCount]`. Both `null` identifies as a single,
  /// unsharded connection — the server's own default when `shard` is
  /// omitted from IDENTIFY entirely.
  final int? shardId;
  final int? shardCount;

  final GatewayTransport Function(Uri) _transportFactory;

  final _stateController = StreamController<GatewayConnectionState>.broadcast();
  final _eventController = StreamController<GatewayEvent>.broadcast();

  GatewayConnectionState _state = const Disconnected();
  GatewayTransport? _transport;
  HeartbeatManager? _heartbeatManager;
  StreamSubscription<String>? _messageSubscription;
  Timer? _reconnectTimer;

  String? _sessionId;
  int? _sequence;
  int _reconnectAttempt = 0;

  GatewayConnectionState get state => _state;
  Stream<GatewayConnectionState> get stateChanges => _stateController.stream;
  Stream<GatewayEvent> get events => _eventController.stream;

  /// [gatewayUrl] with the query params the server actually requires
  /// appended. Verified against `gateway_handler.erl`'s `parse_version`
  /// (rejects anything but the literal string `"1"` with close code
  /// `invalidApiVersion`) and `GatewaySocket.ts`'s `buildGatewayUrl`
  /// (`v`, `encoding`, `compress`). `encoding` is included for
  /// forward-compatible explicitness even though the server currently
  /// hardcodes JSON regardless of its value; `compress` is deliberately
  /// omitted — this client doesn't implement zstd decompression, and an
  /// absent/unrecognized value already defaults to no compression
  /// server-side (`gateway_compress:parse_compression/2`).
  Uri get _connectUrl => gatewayUrl.replace(
    queryParameters: {
      ...gatewayUrl.queryParameters,
      'v': '1',
      'encoding': 'json',
    },
  );

  Future<void> connect() async {
    _reconnectTimer?.cancel();
    _setState(const Connecting());
    final transport = _transportFactory(_connectUrl);
    _transport = transport;
    _messageSubscription = transport.messages.listen(
      _handleRawMessage,
      onDone: _handleTransportClosed,
      onError: (Object error, StackTrace stackTrace) => logger.error(
        'Gateway transport error',
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _heartbeatManager?.stop();
    await _messageSubscription?.cancel();
    await _transport?.close(code: 1000, reason: 'client disconnect');
    _transport = null;
    _sessionId = null;
    _sequence = null;
    _setState(const Disconnected());
  }

  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
    await _eventController.close();
  }

  void _handleRawMessage(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final seq = json['s'] as int?;
    if (seq != null) _sequence = seq;

    final op = GatewayOpcode.fromValue(json['op'] as int);
    switch (op) {
      case GatewayOpcode.hello:
        final helloData = json['d'] as Map<String, dynamic>;
        _startHeartbeat(
          Duration(milliseconds: helloData['heartbeat_interval'] as int),
        );
        _sessionId == null ? _sendIdentify() : _sendResume();
      case GatewayOpcode.dispatch:
        _handleDispatch(json['t'] as String, json['d'] as Map<String, dynamic>);
      case GatewayOpcode.heartbeatAck:
        _heartbeatManager?.acknowledge();
      case GatewayOpcode.heartbeat:
        _sendHeartbeat();
      case GatewayOpcode.invalidSession:
        final resumable = json['d'] as bool? ?? false;
        if (resumable && _sessionId != null) {
          _sendResume();
        } else {
          _sessionId = null;
          _sequence = null;
          _sendIdentify();
        }
      case GatewayOpcode.reconnect:
        unawaited(
          _transport?.close(code: 4000, reason: 'server requested reconnect'),
        );
      case GatewayOpcode.presenceUpdate:
      case GatewayOpcode.voiceStateUpdate:
      case GatewayOpcode.voiceServerPing:
      case GatewayOpcode.resume:
      case GatewayOpcode.identify:
      case GatewayOpcode.requestGuildMembers:
      case GatewayOpcode.gatewayError:
      case GatewayOpcode.lazyRequest:
      case GatewayOpcode.requestGuildCounts:
      case GatewayOpcode.requestChannelMemberCounts:
      case null:
        logger.debug('Unhandled/outbound-only opcode received: ${json['op']}');
    }
  }

  void _handleDispatch(String eventName, Map<String, dynamic> data) {
    // DEBUG, not INFO: fires once per message/reaction/typing tick on an
    // active bot, which would be too noisy for INFO. INFO is reserved for
    // session lifecycle (connect/identify/resume/READY).
    logger.debug('Dispatch: $eventName');
    final event = GatewayEvent.fromDispatch(eventName, data);
    switch (event) {
      case ReadyEvent():
        _sessionId = event.sessionId;
        _reconnectAttempt = 0;
        logger.info(
          'READY — logged in as ${event.user.username} (session ${event.sessionId})',
        );
        _setState(Connected(sessionId: event.sessionId));
      case ResumedEvent():
        _reconnectAttempt = 0;
        logger.info('RESUMED session $_sessionId');
        _setState(Connected(sessionId: _sessionId!));
      case MessageCreateEvent():
      case MessageUpdateEvent():
      case MessageDeleteEvent():
      case MessageReactionAddEvent():
      case MessageReactionRemoveEvent():
      case TypingStartEvent():
      case GuildCreateEvent():
      case GuildUpdateEvent():
      case GuildDeleteEvent():
      case GuildRoleCreateEvent():
      case GuildRoleUpdateEvent():
      case GuildRoleDeleteEvent():
      case GuildMemberAddEvent():
      case GuildMemberUpdateEvent():
      case GuildMemberRemoveEvent():
      case GuildBanAddEvent():
      case GuildBanRemoveEvent():
      case ChannelCreateEvent():
      case ChannelUpdateEvent():
      case ChannelDeleteEvent():
      case UnknownDispatchEvent():
        break;
    }
    _eventController.add(event);
  }

  void _sendIdentify() {
    _setState(const Identifying());
    _send({
      'op': GatewayOpcode.identify.value,
      'd': {
        'token': token,
        'properties': properties,
        'flags': 0,
        if (shardId != null) 'shard': [shardId, shardCount],
      },
    });
  }

  void _sendResume() {
    final sessionId = _sessionId;
    if (sessionId == null) {
      _sendIdentify();
      return;
    }
    _setState(Resuming(sessionId: sessionId));
    _send({
      'op': GatewayOpcode.resume.value,
      'd': {'token': token, 'session_id': sessionId, 'seq': _sequence},
    });
  }

  void _sendHeartbeat() {
    _send({'op': GatewayOpcode.heartbeat.value, 'd': _sequence});
  }

  void _send(Map<String, dynamic> payload) {
    _transport?.send(jsonEncode(payload));
  }

  void _startHeartbeat(Duration interval) {
    _heartbeatManager?.stop();
    _heartbeatManager = HeartbeatManager(
      interval: interval,
      onHeartbeat: _sendHeartbeat,
      onTimeout: _handleHeartbeatTimeout,
    )..start();
  }

  void _handleHeartbeatTimeout() {
    logger.warning('Heartbeat ACK not received in time, reconnecting');
    unawaited(_transport?.close(code: 4009, reason: 'heartbeat timeout'));
  }

  void _handleTransportClosed() {
    _heartbeatManager?.stop();
    final closeCode = _transport == null
        ? null
        : GatewayCloseCode.fromValue(_transport!.closeCode ?? -1);
    final reason = _transport?.closeReason;
    _transport = null;

    if (closeCode?.isRecoverable == false) {
      logger.error(
        'Gateway closed with an unrecoverable code: ${closeCode?.name}${reason != null ? ' ($reason)' : ''}',
      );
      _setState(Closed(closeCode: closeCode, reason: reason));
      return;
    }

    _reconnectAttempt++;
    if (!reconnectPolicy.shouldRetry(_reconnectAttempt)) {
      logger.error(
        'Gateway closed after $_reconnectAttempt reconnect attempts, giving up',
      );
      _setState(Closed(closeCode: closeCode, reason: reason));
      return;
    }

    final delay = reconnectPolicy.delayFor(_reconnectAttempt);
    logger.warning(
      'Gateway connection lost (${closeCode?.name ?? 'no close code'}), '
      'reconnect attempt $_reconnectAttempt in ${delay.inMilliseconds}ms',
    );
    _setState(Reconnecting(attempt: _reconnectAttempt));
    _reconnectTimer = Timer(delay, () {
      unawaited(connect());
    });
  }

  void _setState(GatewayConnectionState newState) {
    _state = newState;
    logger.info('Gateway: $newState');
    _stateController.add(newState);
  }
}
