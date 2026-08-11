import 'package:fake_async/fake_async.dart';
import 'package:fluxer_gateway/fluxer_gateway.dart';
import 'package:test/test.dart';

void main() {
  group('HeartbeatManager', () {
    test('computeNextDelay follows Fluxer\'s jitter formula', () {
      final manager = HeartbeatManager(
        interval: const Duration(milliseconds: 10000),
        onHeartbeat: () {},
        onTimeout: () {},
      );

      // base = max(1000, 10000*0.8) = 8000, jitter = min(1500, 10000*0.05) = 500
      for (var i = 0; i < 20; i++) {
        final delay = manager.computeNextDelay().inMilliseconds;
        expect(delay, inInclusiveRange(8000, 8500));
      }
    });

    test('computeNextDelay respects the 1000ms floor for tiny intervals', () {
      final manager = HeartbeatManager(
        interval: const Duration(milliseconds: 100),
        onHeartbeat: () {},
        onTimeout: () {},
      );

      expect(
        manager.computeNextDelay().inMilliseconds,
        greaterThanOrEqualTo(1000),
      );
    });

    test(
      'sends a heartbeat on each tick, then times out if not acknowledged before the next',
      () {
        fakeAsync((async) {
          var heartbeatCount = 0;
          var timedOut = false;
          final manager = HeartbeatManager(
            interval: const Duration(seconds: 30),
            onHeartbeat: () => heartbeatCount++,
            onTimeout: () => timedOut = true,
          );

          // base = max(1000, 30000*0.8) = 24000, jitter <= min(1500, 30000*0.05) = 1500
          // -> a tick is always due within 25500ms of being scheduled.
          const maxTickDelay = Duration(milliseconds: 25500);

          manager.start();
          async.elapse(
            maxTickDelay,
          ); // tick 1: sends heartbeat, schedules the next
          expect(heartbeatCount, 1);
          expect(timedOut, isFalse);

          async.elapse(
            maxTickDelay,
          ); // tick 2: no ack arrived in between -> timeout
          expect(timedOut, isTrue);
          expect(manager.isRunning, isFalse);
        });
      },
    );

    test('acknowledging before the next tick avoids a timeout', () {
      fakeAsync((async) {
        var heartbeatCount = 0;
        var timedOut = false;
        final manager = HeartbeatManager(
          interval: const Duration(seconds: 30),
          onHeartbeat: () => heartbeatCount++,
          onTimeout: () => timedOut = true,
        );
        const maxTickDelay = Duration(milliseconds: 25500);

        manager.start();
        async.elapse(maxTickDelay); // first tick: sends heartbeat
        manager.acknowledge();

        async.elapse(
          maxTickDelay,
        ); // second tick: acked, sends another heartbeat instead of timing out
        expect(heartbeatCount, 2);
        expect(timedOut, isFalse);
      });
    });

    test('stop() cancels the pending timer', () {
      fakeAsync((async) {
        var heartbeatCount = 0;
        final manager = HeartbeatManager(
          interval: const Duration(seconds: 30),
          onHeartbeat: () => heartbeatCount++,
          onTimeout: () {},
        );

        manager.start();
        expect(manager.isRunning, isTrue);
        manager.stop();

        expect(manager.isRunning, isFalse);
        expect(async.pendingTimers, isEmpty);
        async.elapse(const Duration(seconds: 26));
        expect(heartbeatCount, 0);
      });
    });
  });
}
