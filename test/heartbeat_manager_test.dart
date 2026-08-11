import 'package:fluxer_gateway/fluxer_gateway.dart';
import 'package:test/test.dart';

import 'fakes/fake_timer_scheduler.dart';

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
        final scheduler = FakeTimerScheduler();
        var heartbeatCount = 0;
        var timedOut = false;
        final manager = HeartbeatManager(
          interval: const Duration(seconds: 30),
          onHeartbeat: () => heartbeatCount++,
          onTimeout: () => timedOut = true,
          createTimer: scheduler.schedule,
        );

        manager.start();
        scheduler.fireNext(); // first tick: sends heartbeat, schedules the next
        expect(heartbeatCount, 1);
        expect(timedOut, isFalse);

        scheduler
            .fireNext(); // second tick: no ack arrived in between -> timeout
        expect(timedOut, isTrue);
        expect(manager.isRunning, isFalse);
      },
    );

    test('acknowledging before the next tick avoids a timeout', () {
      final scheduler = FakeTimerScheduler();
      var heartbeatCount = 0;
      var timedOut = false;
      final manager = HeartbeatManager(
        interval: const Duration(seconds: 30),
        onHeartbeat: () => heartbeatCount++,
        onTimeout: () => timedOut = true,
        createTimer: scheduler.schedule,
      );

      manager.start();
      scheduler.fireNext(); // first tick: sends heartbeat
      manager.acknowledge();

      scheduler
          .fireNext(); // second tick: acked, sends another heartbeat instead of timing out
      expect(heartbeatCount, 2);
      expect(timedOut, isFalse);
    });

    test('stop() cancels the pending timer', () {
      final scheduler = FakeTimerScheduler();
      var heartbeatCount = 0;
      final manager = HeartbeatManager(
        interval: const Duration(seconds: 30),
        onHeartbeat: () => heartbeatCount++,
        onTimeout: () {},
        createTimer: scheduler.schedule,
      );

      manager.start();
      expect(scheduler.pendingCount, 1);
      manager.stop();

      expect(manager.isRunning, isFalse);
      expect(scheduler.pendingCount, 0);
      expect(heartbeatCount, 0);
    });
  });
}
