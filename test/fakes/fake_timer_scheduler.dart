import 'dart:async';

/// A deterministic stand-in for [Timer] scheduling: nothing fires on its
/// own, tests explicitly call [fireNext] (or [fireAll]) to control exactly
/// when a scheduled callback runs. This avoids relying on real event-loop
/// ordering between competing zero-delay timers, which is exactly the
/// kind of race a scheduler test shouldn't be sensitive to.
final class FakeTimerScheduler {
  final _pending = <_PendingTimer>[];

  int get pendingCount => _pending.length;

  Timer schedule(Duration duration, void Function() callback) {
    final entry = _PendingTimer(duration, callback);
    _pending.add(entry);
    return _FakeTimer(entry, _pending);
  }

  /// Fires the earliest-scheduled still-pending callback, if any.
  void fireNext() {
    if (_pending.isEmpty) return;
    final entry = _pending.removeAt(0);
    if (!entry.cancelled) entry.callback();
  }

  /// Fires every still-pending callback, in scheduling order. New
  /// callbacks scheduled as a side effect of one firing are included.
  void fireAll() {
    while (_pending.isNotEmpty) {
      fireNext();
    }
  }
}

final class _PendingTimer {
  _PendingTimer(this.duration, this.callback);

  final Duration duration;
  final void Function() callback;
  bool cancelled = false;
}

final class _FakeTimer implements Timer {
  _FakeTimer(this._entry, this._pending);

  final _PendingTimer _entry;
  final List<_PendingTimer> _pending;

  @override
  void cancel() {
    _entry.cancelled = true;
    _pending.remove(_entry);
  }

  @override
  bool get isActive => !_entry.cancelled && _pending.contains(_entry);

  @override
  int get tick => 0;
}
