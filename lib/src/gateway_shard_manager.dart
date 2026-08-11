import 'dart:async';

import 'package:fluxer_utils/fluxer_utils.dart';

import 'connection_state.dart';
import 'gateway_connection.dart';
import 'gateway_event.dart';
import 'gateway_transport.dart';

/// A [GatewayConnectionState] tagged with which shard it belongs to, as
/// delivered on [GatewayShardManager.stateChanges].
typedef ShardStateChange = (int shardId, GatewayConnectionState state);

/// Owns one [GatewayConnection] per shard and merges their event/state
/// streams into single ones a `Bot` facade can consume without caring how
/// many shards are running underneath.
///
/// Shard identify concurrency follows `GatewayBotInfo.sessionStartLimit
/// .maxConcurrency`: shards are grouped into [maxConcurrency] buckets by
/// `shardId % maxConcurrency` (per `gateway_sharding.erl`'s own bucketing),
/// and only one shard per bucket connects at a time, spaced by
/// [identifyPacing]. Different buckets connect concurrently.
final class GatewayShardManager {
  GatewayShardManager({
    required Uri gatewayUrl,
    required String token,
    required this.shardCount,
    this.maxConcurrency = 1,
    this.identifyPacing = const Duration(seconds: 5),
    GatewayConnection Function(int shardId, int shardCount)? connectionFactory,
    GatewayTransport Function(Uri)? transportFactory,
    Map<String, dynamic>? properties,
    Logger? logger,
    RetryPolicy? reconnectPolicy,
  }) : logger = logger ?? const NoopLogger(),
       shards = List.generate(
         shardCount,
         (id) =>
             (connectionFactory ??
             (shardId, shardCount) => GatewayConnection(
               gatewayUrl: gatewayUrl,
               token: token,
               shardId: shardId,
               shardCount: shardCount,
               transportFactory: transportFactory,
               properties: properties,
               logger: logger,
               reconnectPolicy: reconnectPolicy,
             ))(id, shardCount),
       );

  final int shardCount;
  final int maxConcurrency;
  final Duration identifyPacing;
  final Logger logger;
  final List<GatewayConnection> shards;

  final _stateController = StreamController<ShardStateChange>.broadcast();
  final _eventController = StreamController<GatewayEvent>.broadcast();
  final _shardSubscriptions = <StreamSubscription<void>>[];

  Stream<ShardStateChange> get stateChanges => _stateController.stream;
  Stream<GatewayEvent> get events => _eventController.stream;

  Future<void> connect() async {
    for (var i = 0; i < shards.length; i++) {
      final shard = shards[i];
      _shardSubscriptions.add(
        shard.stateChanges.listen((state) => _stateController.add((i, state))),
      );
      _shardSubscriptions.add(shard.events.listen(_eventController.add));
    }

    final buckets = List.generate(maxConcurrency, (_) => <GatewayConnection>[]);
    for (var i = 0; i < shards.length; i++) {
      buckets[i % maxConcurrency].add(shards[i]);
    }
    await Future.wait(buckets.map(_connectBucket));
  }

  Future<void> _connectBucket(List<GatewayConnection> bucket) async {
    for (var i = 0; i < bucket.length; i++) {
      if (i > 0) await Future<void>.delayed(identifyPacing);
      await bucket[i].connect();
    }
  }

  Future<void> disconnect() async {
    await Future.wait(shards.map((s) => s.disconnect()));
  }

  Future<void> dispose() async {
    for (final sub in _shardSubscriptions) {
      await sub.cancel();
    }
    _shardSubscriptions.clear();
    await Future.wait(shards.map((s) => s.dispose()));
    await _stateController.close();
    await _eventController.close();
  }
}
