import 'package:fake_async/fake_async.dart';
import 'package:fluxer_dart_core/fluxer_dart_core.dart';
import 'package:fluxer_dart_gateway/fluxer_dart_gateway.dart';
import 'package:test/test.dart';

import 'fakes/fake_gateway_transport.dart';

void _pump(FakeAsync async, [int rounds = 3]) {
  for (var i = 0; i < rounds; i++) {
    async.elapse(Duration.zero);
  }
}

const _helloPayload = {
  'op': 10,
  'd': {'heartbeat_interval': 45000},
};

void main() {
  late List<FakeGatewayTransport> transports;
  late GatewayConnection connection;

  setUp(() => transports = []);

  GatewayConnection makeConnection({
    Set<String> ignoredEvents = const {},
    Presence? initialPresence,
    Snowflake? initialGuildId,
    SessionFlags sessionFlags = SessionFlags.none,
  }) => GatewayConnection(
    gatewayUrl: Uri.parse('wss://example.invalid/gateway'),
    token: 'test-token',
    transportFactory: (_) {
      final transport = FakeGatewayTransport();
      transports.add(transport);
      return transport;
    },
    ignoredEvents: ignoredEvents,
    initialPresence: initialPresence,
    initialGuildId: initialGuildId,
    sessionFlags: sessionFlags,
  );

  /// Connects and returns the IDENTIFY payload the connection sent.
  Map<String, dynamic> identifyPayload(FakeAsync async) {
    connection.connect();
    final transport = transports.single;
    transport.emit(_helloPayload);
    _pump(async);
    return transport.sentMessages.single['d'] as Map<String, dynamic>;
  }

  group('IDENTIFY', () {
    test('omits the optional fields when nothing opts in', () {
      fakeAsync((async) {
        connection = makeConnection();
        final d = identifyPayload(async);

        expect(d['flags'], 0);
        expect(d.containsKey('ignored_events'), isFalse);
        expect(d.containsKey('presence'), isFalse);
        expect(d.containsKey('initial_guild_id'), isFalse);
      });
    });

    test('upper-cases ignored event names', () {
      fakeAsync((async) {
        connection = makeConnection(
          ignoredEvents: {'typing_start', 'PRESENCE_UPDATE'},
        );
        final d = identifyPayload(async);

        expect(
          d['ignored_events'],
          containsAll(<String>['TYPING_START', 'PRESENCE_UPDATE']),
        );
      });
    });

    test('carries an initial presence and guild', () {
      fakeAsync((async) {
        connection = makeConnection(
          initialPresence: const Presence(
            status: PresenceStatus.doNotDisturb,
            afk: true,
            customStatus: CustomStatus(text: 'busy'),
          ),
          initialGuildId: Snowflake.parse('42'),
        );
        final d = identifyPayload(async);

        expect(d['presence'], {
          'status': 'dnd',
          'afk': true,
          'custom_status': {'text': 'busy'},
        });
        expect(d['initial_guild_id'], '42');
      });
    });

    test('carries the session flags bitfield', () {
      fakeAsync((async) {
        connection = makeConnection(
          sessionFlags: SessionFlags.of([SessionFlag.debounceMessageReactions]),
        );

        expect(identifyPayload(async)['flags'], 2);
      });
    });
  });

  group('outbound commands', () {
    test('updatePresence sends opcode 3 with the presence body', () {
      fakeAsync((async) {
        connection = makeConnection();
        identifyPayload(async);

        connection.updatePresence(
          const Presence(status: PresenceStatus.idle, afk: true),
        );
        _pump(async);

        final sent = transports.single.sentMessages.last;
        expect(sent['op'], GatewayOpcode.presenceUpdate.value);
        expect(sent['d'], {'status': 'idle', 'afk': true});
      });
    });

    test('a cleared custom status sends an explicit null', () {
      fakeAsync((async) {
        connection = makeConnection();
        identifyPayload(async);

        connection.updatePresence(
          Presence.clearCustomStatus(PresenceStatus.online),
        );
        _pump(async);

        final d =
            transports.single.sentMessages.last['d'] as Map<String, dynamic>;
        expect(d.containsKey('custom_status'), isTrue);
        expect(d['custom_status'], isNull);
      });
    });

    test('requestGuildMembers sends opcode 8', () {
      fakeAsync((async) {
        connection = makeConnection();
        identifyPayload(async);

        connection.requestGuildMembers(
          Snowflake.parse('99'),
          query: 'ann',
          limit: 10,
          presences: true,
          nonce: 'n1',
        );
        _pump(async);

        final sent = transports.single.sentMessages.last;
        expect(sent['op'], GatewayOpcode.requestGuildMembers.value);
        expect(sent['d'], {
          'guild_id': '99',
          'query': 'ann',
          'limit': 10,
          'presences': true,
          'nonce': 'n1',
        });
      });
    });

    test('requestGuildMembers omits an unset nonce and user list', () {
      fakeAsync((async) {
        connection = makeConnection();
        identifyPayload(async);

        connection.requestGuildMembers(Snowflake.parse('99'));
        _pump(async);

        final d =
            transports.single.sentMessages.last['d'] as Map<String, dynamic>;
        expect(d.containsKey('nonce'), isFalse);
        expect(d.containsKey('user_ids'), isFalse);
        expect(d.containsKey('presences'), isFalse);
      });
    });
  });
}
