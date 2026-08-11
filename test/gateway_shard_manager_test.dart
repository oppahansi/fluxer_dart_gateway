import 'package:fake_async/fake_async.dart';
import 'package:fluxer_gateway/fluxer_gateway.dart';
import 'package:test/test.dart';

import 'fakes/fake_gateway_transport.dart';

const _helloPayload = {
  'op': 10,
  'd': {'heartbeat_interval': 45000},
};

Map<String, dynamic> _readyPayload(String sessionId) => {
  'op': GatewayOpcode.dispatch.value,
  't': 'READY',
  's': 1,
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

void main() {
  group('GatewayShardManager', () {
    late Map<int, FakeGatewayTransport> transportsByShard;
    late GatewayShardManager manager;

    setUp(() {
      transportsByShard = {};
    });

    tearDown(() async {
      await manager.dispose();
    });

    GatewayShardManager makeManager({
      required int shardCount,
      int maxConcurrency = 1,
      Duration identifyPacing = const Duration(seconds: 5),
    }) {
      return GatewayShardManager(
        gatewayUrl: Uri.parse('wss://example.invalid/gateway'),
        token: 'test-token',
        shardCount: shardCount,
        maxConcurrency: maxConcurrency,
        identifyPacing: identifyPacing,
        connectionFactory: (shardId, count) {
          final transport = FakeGatewayTransport();
          transportsByShard[shardId] = transport;
          return GatewayConnection(
            gatewayUrl: Uri.parse('wss://example.invalid/gateway'),
            token: 'test-token',
            shardId: shardId,
            shardCount: count,
            transportFactory: (_) => transport,
          );
        },
      );
    }

    test('each shard IDENTIFYs with its own shardId', () {
      fakeAsync((async) {
        manager = makeManager(shardCount: 2, maxConcurrency: 2);
        manager.connect();
        async.elapse(Duration.zero);

        for (final shardId in [0, 1]) {
          transportsByShard[shardId]!.emit(_helloPayload);
        }
        async.elapse(Duration.zero);

        expect(transportsByShard[0]!.sentMessages.single['d']['shard'], [0, 2]);
        expect(transportsByShard[1]!.sentMessages.single['d']['shard'], [1, 2]);
      });
    });

    test('shards sharing a max_concurrency bucket connect one at a time', () {
      fakeAsync((async) {
        // maxConcurrency: 1 puts every shard in bucket 0, so shard 1 must
        // wait a full identifyPacing after shard 0 before connecting.
        manager = makeManager(
          shardCount: 2,
          maxConcurrency: 1,
          identifyPacing: const Duration(seconds: 5),
        );
        manager.connect();
        async.elapse(Duration.zero);

        expect(manager.shards[0].state, isA<Connecting>());
        expect(manager.shards[1].state, isA<Disconnected>());

        async.elapse(const Duration(seconds: 5));
        expect(manager.shards[1].state, isA<Connecting>());
      });
    });

    test('shards in different buckets connect concurrently', () {
      fakeAsync((async) {
        manager = makeManager(shardCount: 2, maxConcurrency: 2);
        manager.connect();
        async.elapse(Duration.zero);

        expect(manager.shards[0].state, isA<Connecting>());
        expect(manager.shards[1].state, isA<Connecting>());
      });
    });

    test('stateChanges tags each transition with its shard id', () {
      fakeAsync((async) {
        manager = makeManager(shardCount: 2, maxConcurrency: 2);
        final states = <ShardStateChange>[];
        manager.stateChanges.listen(states.add);

        manager.connect();
        async.elapse(Duration.zero);

        expect(
          states.where((s) => s.$1 == 0 && s.$2 is Connecting),
          hasLength(1),
        );
        expect(
          states.where((s) => s.$1 == 1 && s.$2 is Connecting),
          hasLength(1),
        );
      });
    });

    test('events from every shard are merged onto one stream', () {
      fakeAsync((async) {
        manager = makeManager(shardCount: 2, maxConcurrency: 2);
        final events = <GatewayEvent>[];
        manager.events.listen(events.add);

        manager.connect();
        async.elapse(Duration.zero);

        transportsByShard[0]!.emit(_helloPayload);
        transportsByShard[1]!.emit(_helloPayload);
        async.elapse(Duration.zero);

        transportsByShard[0]!.emit(_readyPayload('shard-0-session'));
        transportsByShard[1]!.emit(_readyPayload('shard-1-session'));
        async.elapse(Duration.zero);

        expect(events.whereType<ReadyEvent>(), hasLength(2));
      });
    });
  });
}
