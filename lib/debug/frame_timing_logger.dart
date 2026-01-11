import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../config/feature_flags.dart';
import '../utils/app_logger.dart';

/// Lightweight frame timing logger for diagnosing jank in debug builds.
class FrameTimingLogger {
  static bool _started = false;
  static final List<FrameTiming> _buffer = [];
  static const int _reportInterval = 30; // frames per summary

  static void start() {
    // Only allow in debug; never log in profile/release
    if (_started || !kDebugMode) return;
    if (!FeatureFlags.logFrameTimings) return;
    _started = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    AppLogger.d('[FrameTimingLogger] Started');
  }

  static void stop() {
    if (!_started) return;
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _started = false;
    AppLogger.d('[FrameTimingLogger] Stopped');
  }

  static void _onTimings(List<FrameTiming> timings) {
    _buffer.addAll(timings);
    if (_buffer.length >= _reportInterval) {
      final ms = _buffer.map((t) => t.totalSpan.inMilliseconds).toList();
      ms.sort();
      double percentile(int p) =>
          ms[(ms.length * p / 100).clamp(0, (ms.length - 1).toDouble()).toInt()]
              .toDouble();
      final avg = ms.reduce((a, b) => a + b) / ms.length;
      AppLogger.d(
        '[FrameTiming] n=${ms.length} avg=${avg.toStringAsFixed(1)}ms p50=${percentile(50)} p90=${percentile(90)} p99=${percentile(99)} worst=${ms.last}',
      );
      _buffer.clear();
    }
  }
}
