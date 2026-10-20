import 'dart:async';
import 'dart:convert';

import 'package:fluxer_dart_core/fluxer_dart_core.dart';
import 'package:fluxer_dart_utils/fluxer_dart_utils.dart';

import 'connection_state.dart';
import 'gateway_event.dart';
import 'gateway_transport.dart';
import 'guild_subscription.dart';
import 'heartbeat_manager.dart';
import 'opcodes.dart';
import 'session_flags.dart';
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
/// [GatewayTransport]: package:fluxer_dart_gateway/src/gateway_transport.dart
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
    this.ignoredEvents = const {},
    this.initialPresence,
    this.initialGuildId,
    this.sessionFlags = SessionFlags.none,
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
             'browser': 'fluxer_dart',
             'device': 'fluxer_dart',
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

  /// DISPATCH names the server drops before they reach this session.
  ///
  /// Fluxer has no intent bitfield; suppressing unwanted traffic is done
  /// here instead. Up to 256 names, matched case-insensitively. A
  /// `MESSAGE_CREATE` still arrives despite being listed if the message
  /// mentions this session's user, or sets `mention_here` or
  /// `mention_everyone`. Suppressed dispatches consume no sequence
  /// number, so listing an event leaves no gaps behind.
  final Set<String> ignoredEvents;

  /// Presence published with IDENTIFY. Omitted leaves the account's
  /// current presence untouched.
  final Presence? initialPresence;

  /// Guild marked active for this session at IDENTIFY.
  final Snowflake? initialGuildId;

  /// Session behaviour flags sent with IDENTIFY.
  final SessionFlags sessionFlags;

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
        _handleDispatch(json['t'] as String, json['d']);
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
      case GatewayOpcode.requestForumUnreads:
      case null:
        logger.debug('Unhandled/outbound-only opcode received: ${json['op']}');
    }
  }

  /// [data] is untyped because a dispatch payload is not always a JSON
  /// object; see [GatewayEvent.fromDispatch].
  void _handleDispatch(String eventName, Object? data) {
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
      case ChannelUpdateBulkEvent():
      case GuildRoleUpdateBulkEvent():
      case GuildMembersChunkEvent():
      case RateLimitedEvent():
      case UserUpdateEvent():
      case GuildSyncEvent():
      case PresenceUpdateEvent():
      case PresenceUpdateBulkEvent():
      case GuildMemberListUpdateEvent():
      case ThreadMemberListUpdateEvent():
      case GuildCountsUpdateEvent():
      case ChannelMemberCountsUpdateEvent():
      case ForumUnreadsEvent():
      case VoiceStateUpdateEvent():
      case MessageDeleteBulkEvent():
      case MessageReactionRemoveAllEvent():
      case MessageReactionRemoveEmojiEvent():
      case ChannelPinsUpdateEvent():
      case GuildEmojisUpdateEvent():
      case GuildStickersUpdateEvent():
      case GuildAuditLogEntryCreateEvent():
      case WebhooksUpdateEvent():
      case InviteCreateEvent():
      case InviteDeleteEvent():
      case ThreadCreateEvent():
      case ThreadUpdateEvent():
      case ThreadDeleteEvent():
      case ThreadListSyncEvent():
      case ThreadMemberUpdateEvent():
      case ThreadMembersUpdateEvent():
      case SessionsReplaceEvent():
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
        'flags': sessionFlags.value,
        if (ignoredEvents.isNotEmpty)
          'ignored_events': ignoredEvents
              .map((e) => e.toUpperCase())
              .toList(growable: false),
        if (initialPresence != null) 'presence': initialPresence!.toJson(),
        if (initialGuildId != null)
          'initial_guild_id': initialGuildId!.toJson(),
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

  /// Replaces this session's published presence.
  ///
  /// Rate limited to five commands per 20 seconds; the server drops
  /// excess commands rather than answering them, and there is no
  /// acknowledgement either way.
  void updatePresence(Presence presence) {
    _send({'op': GatewayOpcode.presenceUpdate.value, 'd': presence.toJson()});
  }

  /// Asks for guild members, answered asynchronously as one or more
  /// `GUILD_MEMBERS_CHUNK` dispatches rather than a return value.
  ///
  /// A full member list (no [query], no [userIds]) may be requested once
  /// per guild every 30 seconds; a request inside that window is answered
  /// by `RATE_LIMITED` instead. Filtered requests are not limited that
  /// way. [limit] caps results at 100;
  /// leaving it at 0 with a [query] set returns 25, and leaving both
  /// unset requests the full member list, which additionally requires one
  /// of `manageRoles`, `kickMembers` or `banMembers`. [nonce] is echoed
  /// back on the resulting chunks so concurrent requests can be told
  /// apart, and is capped at 32 bytes.
  void requestGuildMembers(
    Snowflake guildId, {
    String query = '',
    int limit = 0,
    List<Snowflake> userIds = const [],
    bool presences = false,
    String? nonce,
  }) {
    _send({
      'op': GatewayOpcode.requestGuildMembers.value,
      'd': {
        'guild_id': guildId.toJson(),
        'query': query,
        'limit': limit,
        if (userIds.isNotEmpty)
          'user_ids': userIds.map((id) => id.toJson()).toList(growable: false),
        if (presences) 'presences': true,
        'nonce': ?nonce,
      },
    });
  }

  /// Sets this session's per-guild subscriptions (Lazy Request, opcode
  /// 14). Answered, depending on the options, by `GUILD_SYNC`,
  /// `GUILD_MEMBER_LIST_UPDATE`, `THREAD_MEMBER_LIST_UPDATE` and
  /// `PRESENCE_UPDATE`; never by an error. A guild this session is not
  /// connected to is skipped.
  void lazyRequest(Map<Snowflake, GuildSubscription> subscriptions) {
    _send({
      'op': GatewayOpcode.lazyRequest.value,
      'd': {
        'subscriptions': {
          for (final MapEntry(:key, :value) in subscriptions.entries)
            key.toJson(): value.toJson(),
        },
      },
    });
  }

  /// Asks for member and online counts, answered by one
  /// `GUILD_COUNTS_UPDATE`. At most 100 guilds; [nonce] (1-64 bytes) is
  /// echoed back.
  void requestGuildCounts(List<Snowflake> guildIds, {String? nonce}) {
    _send({
      'op': GatewayOpcode.requestGuildCounts.value,
      'd': {
        'guild_ids': [for (final id in guildIds) id.toJson()],
        'nonce': ?nonce,
      },
    });
  }

  /// Asks for member and online counts of up to 25 channels in one
  /// guild, answered by one `CHANNEL_MEMBER_COUNTS_UPDATE`. [nonce]
  /// (1-64 bytes) is echoed back.
  void requestChannelMemberCounts(
    Snowflake guildId,
    List<Snowflake> channelIds, {
    String? nonce,
  }) {
    _send({
      'op': GatewayOpcode.requestChannelMemberCounts.value,
      'd': {
        'guild_id': guildId.toJson(),
        'channel_ids': [for (final id in channelIds) id.toJson()],
        'nonce': ?nonce,
      },
    });
  }

  /// Asks for unread counts of up to 40 posts in a forum or media
  /// channel, answered by `FORUM_UNREADS`. The command takes no nonce.
  void requestForumUnreads(
    Snowflake guildId,
    Snowflake channelId,
    List<ForumUnreadRequest> threads,
  ) {
    _send({
      'op': GatewayOpcode.requestForumUnreads.value,
      'd': {
        'guild_id': guildId.toJson(),
        'channel_id': channelId.toJson(),
        'threads': [for (final t in threads) t.toJson()],
      },
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
