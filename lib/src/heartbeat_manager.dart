import 'dart:async';
import 'dart:math';

/// Schedules gateway heartbeats and tracks whether the server acknowledged
/// the previous one, as its own single-responsibility, independently
/// testable class — not inlined into the connection/socket class.
///
/// Jitter formula verified against `GatewaySocket.ts`'s
/// `computeNextHeartbeatDelay`: `base = max(1000ms, interval * 0.8)`,
/// `jitter = min(1500ms, interval * 0.05)`, delay = `base + random(0,
/// jitter)`.
final class HeartbeatManager {
  HeartbeatManager({
    required this.interval,
    required this.onHeartbeat,
    required this.onTimeout,
    Random? random,
  }) : _random = random ?? Random();

  /// The `heartbeat_interval` from HELLO.
  final Duration interval;

  /// Called each time a heartbeat should be sent.
  final void Function() onHeartbeat;

  /// Called if a heartbeat ACK isn't received before the next heartbeat
  /// is due — the caller should treat this as a dead connection and
  /// reconnect.
  final void Function() onTimeout;

  final Random _random;

  Timer? _timer;
  bool _awaitingAck = false;

  bool get isRunning => _timer != null;

  /// Starts the heartbeat loop. Per Fluxer's own client behaviour, the
  /// very first heartbeat is also jittered rather than sent immediately.
  void start() {
    stop();
    _scheduleNext();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _awaitingAck = false;
  }

  /// Call when a HEARTBEAT_ACK is received from the server.
  void acknowledge() {
    _awaitingAck = false;
  }

  Duration computeNextDelay() {
    final intervalMs = interval.inMilliseconds;
    if (intervalMs <= 0) return const Duration(milliseconds: 1000);
    final baseMs = max(1000, (intervalMs * 0.8).floor());
    final jitterMs = min(1500, (intervalMs * 0.05).floor());
    return Duration(milliseconds: baseMs + _random.nextInt(jitterMs + 1));
  }

  void _scheduleNext() {
    _timer = Timer(computeNextDelay(), _tick);
  }

  void _tick() {
    if (_awaitingAck) {
      stop();
      onTimeout();
      return;
    }
    _awaitingAck = true;
    onHeartbeat();
    _scheduleNext();
  }
}
