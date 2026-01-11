import 'dart:async';
import 'dart:math';

/// Lightweight per-key exponential backoff scheduler with jitter.
/// Use to throttle background refreshes (e.g., price/image) to avoid bursts.
class BackoffScheduler {
  BackoffScheduler._();
  static final BackoffScheduler instance = BackoffScheduler._();

  final Map<String, _BackoffState> _states = {};

  /// Register a success so next attempt resets.
  void success(String key) {
    final s = _states[key];
    if (s != null) {
      s.failCount = 0;
      s.nextDelay = s.base;
      s.nextAllowed = DateTime.now();
    }
  }

  /// Schedule a task respecting backoff.
  /// If a task is already scheduled earlier than now, it won't duplicate.
  void schedule(
    String key,
    FutureOr<void> Function() task, {
    Duration base = const Duration(seconds: 2),
    Duration max = const Duration(minutes: 2),
  }) {
    final now = DateTime.now();
    final state = _states.putIfAbsent(
      key,
      () => _BackoffState(base: base, max: max),
    );
    if (state.timer != null) return; // Already queued.
    if (state.nextAllowed.isBefore(now)) {
      _run(key, task);
    } else {
      final delay = state.nextAllowed.difference(now);
      state.timer = Timer(delay, () => _run(key, task));
    }
  }

  void _run(String key, FutureOr<void> Function() task) async {
    final state = _states[key];
    if (state == null) return;
    state.timer?.cancel();
    state.timer = null;
    try {
      await task();
      success(key); // Reset on success.
    } catch (_) {
      state.failCount++;
      final rand = Random();
      final mult = pow(2, state.failCount).toInt();
      var next = state.base * mult;
      if (next > state.max) next = state.max;
      final jitterMs = rand.nextInt(next.inMilliseconds + 1); // Full jitter.
      state.nextDelay = Duration(milliseconds: jitterMs);
      state.nextAllowed = DateTime.now().add(state.nextDelay);
      state.timer = Timer(state.nextDelay, () => _run(key, task));
    }
  }
}

class _BackoffState {
  final Duration base;
  final Duration max;
  int failCount = 0;
  Timer? timer;
  Duration nextDelay;
  DateTime nextAllowed;
  _BackoffState({required this.base, required this.max})
    : nextDelay = base,
      nextAllowed = DateTime.now();
}
