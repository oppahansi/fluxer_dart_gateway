import 'package:fluxer_gateway/fluxer_gateway.dart';
import 'package:fluxer_utils/fluxer_utils.dart';
import 'package:test/test.dart';

import 'fakes/fake_gateway_transport.dart';
import 'fakes/fake_timer_scheduler.dart';

Map<String, dynamic> _readyPayload({
  String sessionId = 'session-1',
  int seq = 1,
}) => {
  'op': GatewayOpcode.dispatch.value,
  't': 'READY',
  's': seq,
  'd': {
    'session_id': sessionId,
    'user': {
      'id': '1',
      'username': 'bot',
      'discriminator': '0',
      'global_name': null,
      'avatar': null,
      'avatar_color': null,
      'bot': true,
      'system': false,
    },
  },
};

const _helloPayload = {
  'op': 10,
  'd': {'heartbeat_interval': 45000},
};

void main() {
  group('GatewayConnection', () {
    late List<FakeGatewayTransport> transports;
    late FakeTimerScheduler scheduler;
    late GatewayConnection connection;

    setUp(() {
      transports = [];
      scheduler = FakeTimerScheduler();
    });

    tearDown(() async {
      await connection.dispose();
    });

    GatewayConnection makeConnection({RetryPolicy? reconnectPolicy}) {
      return GatewayConnection(
        gatewayUrl: Uri.parse('wss://example.invalid/gateway'),
        token: 'test-token',
        transportFactory: (_) {
          final transport = FakeGatewayTransport();
          transports.add(transport);
          return transport;
        },
        createTimer: scheduler.schedule,
        reconnectPolicy: reconnectPolicy,
      );
    }

    test('happy path: HELLO -> IDENTIFY -> READY -> Connected', () async {
      connection = makeConnection();
      final events = <GatewayEvent>[];
      connection.events.listen(events.add);

      await connection.connect();
      expect(connection.state, isA<Connecting>());

      final transport = transports.single;
      transport.emit(_helloPayload);
      await Future<void>.delayed(Duration.zero);

      expect(connection.state, isA<Identifying>());
      expect(transport.sentMessages.single['op'], GatewayOpcode.identify.value);
      expect(transport.sentMessages.single['d']['token'], 'test-token');

      transport.emit(_readyPayload());
      await Future<void>.delayed(Duration.zero);

      expect(connection.state, isA<Connected>());
      expect((connection.state as Connected).sessionId, 'session-1');
      expect(events.whereType<ReadyEvent>(), hasLength(1));
    });

    test(
      'MESSAGE_CREATE dispatch is decoded and delivered on events',
      () async {
        connection = makeConnection();
        final events = <GatewayEvent>[];
        connection.events.listen(events.add);

        await connection.connect();
        final transport = transports.single;
        transport.emit(_helloPayload);
        await Future<void>.delayed(Duration.zero);
        transport.emit(_readyPayload());
        await Future<void>.delayed(Duration.zero);

        transport.emit({
          'op': GatewayOpcode.dispatch.value,
          't': 'MESSAGE_CREATE',
          's': 2,
          'd': {
            'id': '10',
            'channel_id': '20',
            'author': {
              'id': '30',
              'username': 'someone',
              'discriminator': '0',
              'global_name': null,
              'avatar': null,
              'avatar_color': null,
              'bot': false,
              'system': false,
            },
            'type': 0,
            'flags': 0,
            'content': '!ping',
            'timestamp': '2026-08-11T12:00:00.000Z',
            'edited_timestamp': null,
            'pinned': false,
            'mention_everyone': false,
            'tts': false,
            'mentions': <dynamic>[],
            'mention_roles': <dynamic>[],
          },
        });
        await Future<void>.delayed(Duration.zero);

        final messageEvents = events.whereType<MessageCreateEvent>();
        expect(messageEvents, hasLength(1));
        expect(messageEvents.single.message.content, '!ping');
      },
    );

    test(
      'acknowledged heartbeats keep the connection alive; a missed ack closes it',
      () async {
        connection = makeConnection();
        await connection.connect();
        final transport = transports.single;
        transport.emit(_helloPayload);
        await Future<void>.delayed(Duration.zero);
        transport.emit(_readyPayload());
        await Future<void>.delayed(Duration.zero);

        expect(
          scheduler.pendingCount,
          1,
          reason: 'heartbeat manager should have scheduled its first tick',
        );
        scheduler.fireNext(); // tick 1: sends a heartbeat
        expect(
          transport.sentMessages.any(
            (m) => m['op'] == GatewayOpcode.heartbeat.value,
          ),
          isTrue,
        );

        transport.emit({'op': GatewayOpcode.heartbeatAck.value});
        await Future<void>.delayed(Duration.zero);
        scheduler
            .fireNext(); // tick 2: acked in time -> another heartbeat, not a timeout
        expect(transport.closedByClient, isFalse);

        // No ack this time -> tick 3 should detect the miss and close.
        scheduler.fireNext();
        expect(transport.closedByClient, isTrue);
      },
    );

    test(
      'reconnects and RESUMEs after a recoverable server-side close',
      () async {
        connection = makeConnection(
          reconnectPolicy: ExponentialBackoffRetryPolicy(jitterFraction: 0),
        );
        await connection.connect();
        final firstTransport = transports.single;
        firstTransport.emit(_helloPayload);
        await Future<void>.delayed(Duration.zero);
        firstTransport.emit(_readyPayload(sessionId: 'session-42'));
        await Future<void>.delayed(Duration.zero);

        await firstTransport.simulateServerClose(
          GatewayCloseCode.unknownError.value,
        );
        await Future<void>.delayed(Duration.zero);
        expect(connection.state, isA<Reconnecting>());
        expect(
          transports,
          hasLength(1),
          reason: 'reconnect timer has not fired yet',
        );

        scheduler.fireNext(); // reconnect timer fires -> connect()
        expect(transports, hasLength(2));
        final secondTransport = transports[1];

        secondTransport.emit(_helloPayload);
        await Future<void>.delayed(Duration.zero);

        expect(connection.state, isA<Resuming>());
        final resumePayload = secondTransport.sentMessages.single;
        expect(resumePayload['op'], GatewayOpcode.resume.value);
        expect(resumePayload['d']['session_id'], 'session-42');

        secondTransport.emit({
          'op': GatewayOpcode.dispatch.value,
          't': 'RESUMED',
          'd': <String, dynamic>{},
        });
        await Future<void>.delayed(Duration.zero);
        expect(connection.state, isA<Connected>());
      },
    );

    test('does not reconnect after an unrecoverable close code', () async {
      connection = makeConnection();
      await connection.connect();
      final transport = transports.single;
      transport.emit(_helloPayload);
      await Future<void>.delayed(Duration.zero);

      await transport.simulateServerClose(
        GatewayCloseCode.authenticationFailed.value,
      );
      await Future<void>.delayed(Duration.zero);

      expect(connection.state, isA<Closed>());
      expect(
        (connection.state as Closed).closeCode,
        GatewayCloseCode.authenticationFailed,
      );
      expect(
        transports,
        hasLength(1),
        reason: 'no reconnect attempt should have created a second transport',
      );
      expect(
        scheduler.pendingCount,
        0,
        reason: 'no reconnect timer should have been scheduled',
      );
    });

    test(
      'disconnect() closes the transport and returns to Disconnected',
      () async {
        connection = makeConnection();
        await connection.connect();
        final transport = transports.single;
        transport.emit(_helloPayload);
        await Future<void>.delayed(Duration.zero);

        await connection.disconnect();

        expect(connection.state, isA<Disconnected>());
        expect(transport.closedByClient, isTrue);
      },
    );
  });
}
