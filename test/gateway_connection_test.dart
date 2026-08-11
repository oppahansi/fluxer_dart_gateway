import 'package:fake_async/fake_async.dart';
import 'package:fluxer_gateway/fluxer_gateway.dart';
import 'package:fluxer_utils/fluxer_utils.dart';
import 'package:test/test.dart';

import 'fakes/fake_gateway_transport.dart';

/// A single `elapse(Duration.zero)` drains one round of microtasks/timers,
/// but a broadcast [StreamController]'s `cancel()`/`close()` pair (as used
/// by [GatewayConnection.disconnect]) can take more than one round to
/// fully settle — verified empirically: `cancel()`'s future doesn't
/// resolve until *after* the paired `close()` has, which itself needs its
/// own round. A few empty rounds is cheap insurance against that kind of
/// multi-hop resolution chain, here and anywhere else it might come up.
void _pump(FakeAsync async, [int rounds = 3]) {
  for (var i = 0; i < rounds; i++) {
    async.elapse(Duration.zero);
  }
}

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

// base = max(1000, 45000*0.8) = 36000, jitter <= min(1500, 45000*0.05) = 1500
// -> a single heartbeat tick is always due within this window.
const _maxHeartbeatDelay = Duration(milliseconds: 37500);

void main() {
  group('GatewayConnection', () {
    late List<FakeGatewayTransport> transports;
    late GatewayConnection connection;

    setUp(() {
      transports = [];
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
        reconnectPolicy: reconnectPolicy,
      );
    }

    test('happy path: HELLO -> IDENTIFY -> READY -> Connected', () {
      fakeAsync((async) {
        connection = makeConnection();
        final events = <GatewayEvent>[];
        connection.events.listen(events.add);

        connection.connect();
        expect(connection.state, isA<Connecting>());

        final transport = transports.single;
        transport.emit(_helloPayload);
        _pump(async);

        expect(connection.state, isA<Identifying>());
        expect(
          transport.sentMessages.single['op'],
          GatewayOpcode.identify.value,
        );
        expect(transport.sentMessages.single['d']['token'], 'test-token');

        transport.emit(_readyPayload());
        _pump(async);

        expect(connection.state, isA<Connected>());
        expect((connection.state as Connected).sessionId, 'session-1');
        expect(events.whereType<ReadyEvent>(), hasLength(1));
      });
    });

    test('MESSAGE_CREATE dispatch is decoded and delivered on events', () {
      fakeAsync((async) {
        connection = makeConnection();
        final events = <GatewayEvent>[];
        connection.events.listen(events.add);

        connection.connect();
        final transport = transports.single;
        transport.emit(_helloPayload);
        _pump(async);
        transport.emit(_readyPayload());
        _pump(async);

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
        _pump(async);

        final messageEvents = events.whereType<MessageCreateEvent>();
        expect(messageEvents, hasLength(1));
        expect(messageEvents.single.message.content, '!ping');
      });
    });

    test(
      'acknowledged heartbeats keep the connection alive; a missed ack closes it',
      () {
        fakeAsync((async) {
          connection = makeConnection();
          connection.connect();
          final transport = transports.single;
          transport.emit(_helloPayload);
          _pump(async);
          transport.emit(_readyPayload());
          _pump(async);

          expect(
            async.pendingTimers,
            hasLength(1),
            reason: 'heartbeat manager should have scheduled its first tick',
          );
          async.elapse(_maxHeartbeatDelay); // tick 1: sends a heartbeat
          expect(
            transport.sentMessages.any(
              (m) => m['op'] == GatewayOpcode.heartbeat.value,
            ),
            isTrue,
          );

          transport.emit({'op': GatewayOpcode.heartbeatAck.value});
          _pump(async);
          async.elapse(
            _maxHeartbeatDelay,
          ); // tick 2: acked in time -> another heartbeat, not a timeout
          expect(transport.closedByClient, isFalse);

          // No ack this time -> tick 3 should detect the miss and close.
          async.elapse(_maxHeartbeatDelay);
          expect(transport.closedByClient, isTrue);
        });
      },
    );

    test('reconnects and RESUMEs after a recoverable server-side close', () {
      fakeAsync((async) {
        connection = makeConnection(
          reconnectPolicy: ExponentialBackoffRetryPolicy(jitterFraction: 0),
        );
        connection.connect();
        final firstTransport = transports.single;
        firstTransport.emit(_helloPayload);
        _pump(async);
        firstTransport.emit(_readyPayload(sessionId: 'session-42'));
        _pump(async);

        firstTransport.simulateServerClose(GatewayCloseCode.unknownError.value);
        _pump(async);
        expect(connection.state, isA<Reconnecting>());
        expect(
          transports,
          hasLength(1),
          reason: 'reconnect timer has not fired yet',
        );

        async.elapse(
          const Duration(milliseconds: 500),
        ); // reconnect timer (500ms, zero jitter) fires -> connect()
        expect(transports, hasLength(2));
        final secondTransport = transports[1];

        secondTransport.emit(_helloPayload);
        _pump(async);

        expect(connection.state, isA<Resuming>());
        final resumePayload = secondTransport.sentMessages.single;
        expect(resumePayload['op'], GatewayOpcode.resume.value);
        expect(resumePayload['d']['session_id'], 'session-42');

        secondTransport.emit({
          'op': GatewayOpcode.dispatch.value,
          't': 'RESUMED',
          'd': <String, dynamic>{},
        });
        _pump(async);
        expect(connection.state, isA<Connected>());
      });
    });

    test('does not reconnect after an unrecoverable close code', () {
      fakeAsync((async) {
        connection = makeConnection();
        connection.connect();
        final transport = transports.single;
        transport.emit(_helloPayload);
        _pump(async);

        transport.simulateServerClose(
          GatewayCloseCode.authenticationFailed.value,
        );
        _pump(async);

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
          async.pendingTimers,
          isEmpty,
          reason: 'no reconnect timer should have been scheduled',
        );
      });
    });

    // Deliberately a plain async test, not fakeAsync: it doesn't assert
    // anything time-based (no heartbeat/reconnect ticks to fire), and
    // `StreamSubscription.cancel()` on a broadcast controller — which
    // `disconnect()` awaits — turns out not to resolve under fake_async's
    // `elapse()` no matter how many rounds you pump it (verified against
    // real, non-fake execution: `cancel()` resolves immediately there, so
    // this is a fake_async-specific quirk, not a bug in `disconnect()`).
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
