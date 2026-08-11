import 'package:fluxer_gateway/fluxer_gateway.dart';
import 'package:fluxer_utils/fluxer_utils.dart';
import 'package:test/test.dart';

import 'fakes/fake_gateway_transport.dart';

final class _RecordingLogger extends Logger {
  final entries = <(LogLevel, String)>[];

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    entries.add((level, message));
  }

  Iterable<String> messagesAt(LogLevel level) =>
      entries.where((e) => e.$1 == level).map((e) => e.$2);
}

const _helloPayload = {
  'op': 10,
  'd': {'heartbeat_interval': 45000},
};

Map<String, dynamic> _readyPayload({String sessionId = 'session-1'}) => {
  'op': GatewayOpcode.dispatch.value,
  't': 'READY',
  's': 1,
  'd': {
    'session_id': sessionId,
    'user': {
      'id': '1',
      'username': 'MarlinMammut',
      'discriminator': '0',
      'global_name': null,
      'avatar': null,
      'avatar_color': null,
      'bot': true,
      'system': false,
    },
  },
};

void main() {
  group('GatewayConnection logging', () {
    late _RecordingLogger logger;
    late List<FakeGatewayTransport> transports;
    late GatewayConnection connection;

    setUp(() {
      logger = _RecordingLogger();
      transports = [];
      connection = GatewayConnection(
        gatewayUrl: Uri.parse('wss://example.invalid/gateway'),
        token: 't',
        logger: logger,
        transportFactory: (_) {
          final transport = FakeGatewayTransport();
          transports.add(transport);
          return transport;
        },
      );
    });

    tearDown(() async {
      await connection.dispose();
    });

    test('state transitions are logged at INFO', () async {
      await connection.connect();
      transports.single.emit(_helloPayload);
      await Future<void>.delayed(Duration.zero);

      final infoMessages = logger.messagesAt(LogLevel.info).toList();
      expect(infoMessages, contains(contains('Connecting')));
      expect(infoMessages, contains(contains('Identifying')));
    });

    test(
      'READY is logged at INFO with the bot username and session id',
      () async {
        await connection.connect();
        transports.single.emit(_helloPayload);
        await Future<void>.delayed(Duration.zero);
        transports.single.emit(_readyPayload(sessionId: 'abc123'));
        await Future<void>.delayed(Duration.zero);

        final infoMessages = logger.messagesAt(LogLevel.info).toList();
        expect(
          infoMessages,
          contains(allOf(contains('MarlinMammut'), contains('abc123'))),
        );
      },
    );

    test(
      'individual dispatch events are logged at DEBUG, not INFO (avoids per-message spam)',
      () async {
        await connection.connect();
        transports.single.emit(_helloPayload);
        await Future<void>.delayed(Duration.zero);
        transports.single.emit(_readyPayload());
        await Future<void>.delayed(Duration.zero);

        expect(logger.messagesAt(LogLevel.debug), contains(contains('READY')));
        expect(
          logger.messagesAt(LogLevel.info),
          isNot(contains(contains('Dispatch'))),
        );
      },
    );

    test('an unrecoverable close is logged at ERROR', () async {
      await connection.connect();
      final transport = transports.single;
      transport.emit(_helloPayload);
      await Future<void>.delayed(Duration.zero);

      await transport.simulateServerClose(
        GatewayCloseCode.authenticationFailed.value,
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        logger.messagesAt(LogLevel.error),
        contains(contains('unrecoverable')),
      );
    });

    test(
      'a recoverable close scheduling a reconnect is logged at WARNING',
      () async {
        connection = GatewayConnection(
          gatewayUrl: Uri.parse('wss://example.invalid/gateway'),
          token: 't',
          logger: logger,
          transportFactory: (_) {
            final transport = FakeGatewayTransport();
            transports.add(transport);
            return transport;
          },
          reconnectPolicy: ExponentialBackoffRetryPolicy(jitterFraction: 0),
        );
        await connection.connect();
        final transport = transports.single;
        transport.emit(_helloPayload);
        await Future<void>.delayed(Duration.zero);

        await transport.simulateServerClose(
          GatewayCloseCode.unknownError.value,
        );
        await Future<void>.delayed(Duration.zero);

        expect(
          logger.messagesAt(LogLevel.warning),
          contains(contains('reconnect attempt 1')),
        );
      },
    );
  });
}
