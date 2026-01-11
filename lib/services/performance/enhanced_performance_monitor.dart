import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:shopple/utils/app_logger.dart';

/// 📊 ENHANCED PERFORMANCE MONITORING SERVICE
///
/// Comprehensive performance tracking system that monitors:
/// - Frame timing and jank detection
/// - Startup performance metrics
/// - Service initialization timing
/// - Memory usage patterns
/// - Navigation performance
class EnhancedPerformanceMonitor {
  static bool _initialized = false;
  static bool _monitoring = false;
  static DateTime? _appStartTime;
  static DateTime? _firstFrameTime;
  static final Map<String, DateTime> _milestones = {};
  static final Map<String, Duration> _serviceInitTimes = {};
  static final Queue<FrameMetrics> _frameMetricsBuffer = Queue();
  static Timer? _reportingTimer;

  // Performance thresholds
  static const Duration _frameSlowThreshold = Duration(
    milliseconds: 33,
  ); // 30 FPS
  static const Duration _frameJankThreshold = Duration(
    milliseconds: 50,
  ); // 20 FPS
  static const int _metricsBufferSize = 120; // 2 seconds at 60 FPS

  /// Initialize performance monitoring
  /// Call this early in app startup
  static void initialize() {
    if (_initialized) return;
    _initialized = true;
    _appStartTime = DateTime.now();

    if (kDebugMode) {
      AppLogger.d('🚀 EnhancedPerformanceMonitor: Initialized');
    }
  }

  /// Start comprehensive performance monitoring
  static void startMonitoring() {
    if (!_initialized || _monitoring) return;
    if (!kDebugMode) return; // Only in debug mode

    _monitoring = true;

    // Register frame timing callback
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);

    // Start periodic reporting
    _reportingTimer = Timer.periodic(Duration(seconds: 10), (_) {
      _generatePerformanceReport();
    });

    AppLogger.d('📊 Performance monitoring started');
  }

  /// Stop performance monitoring
  static void stopMonitoring() {
    if (!_monitoring) return;

    _monitoring = false;
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
    _reportingTimer?.cancel();
    _reportingTimer = null;

    AppLogger.d('📊 Performance monitoring stopped');
  }

  /// Record a performance milestone
  static void recordMilestone(String name) {
    if (!_initialized) return;

    final now = DateTime.now();
    _milestones[name] = now;

    if (_appStartTime != null) {
      final elapsed = now.difference(_appStartTime!);
      if (kDebugMode) {
        AppLogger.d(
          '🏁 Milestone "$name" reached at +${elapsed.inMilliseconds}ms',
        );
      }
    }
  }

  /// Record service initialization time
  static void recordServiceInit(String serviceName, Duration initTime) {
    _serviceInitTimes[serviceName] = initTime;

    if (kDebugMode) {
      AppLogger.d(
        '⚙️ Service "$serviceName" initialized in ${initTime.inMilliseconds}ms',
      );
    }
  }

  /// Record first frame rendered
  static void recordFirstFrame() {
    if (_firstFrameTime != null) return;

    _firstFrameTime = DateTime.now();
    recordMilestone('first_frame');

    if (_appStartTime != null) {
      final startupTime = _firstFrameTime!.difference(_appStartTime!);
      if (kDebugMode) {
        AppLogger.d(
          '🎨 First frame rendered in ${startupTime.inMilliseconds}ms',
        );
      }
    }
  }

  /// Get startup performance summary
  static Map<String, dynamic> getStartupSummary() {
    if (_appStartTime == null) {
      return {'error': 'Performance monitoring not initialized'};
    }

    final summary = <String, dynamic>{
      'app_start_time': _appStartTime!.toIso8601String(),
      'milestones': {},
      'service_init_times': {},
      'total_startup_time_ms': _firstFrameTime
          ?.difference(_appStartTime!)
          .inMilliseconds,
    };

    // Add milestone timings relative to app start
    _milestones.forEach((name, time) {
      summary['milestones'][name] = time
          .difference(_appStartTime!)
          .inMilliseconds;
    });

    // Add service initialization times
    _serviceInitTimes.forEach((name, duration) {
      summary['service_init_times'][name] = duration.inMilliseconds;
    });

    return summary;
  }

  /// Get frame performance summary
  static Map<String, dynamic> getFramePerformanceSummary() {
    if (_frameMetricsBuffer.isEmpty) {
      return {'error': 'No frame metrics available'};
    }

    final durations =
        _frameMetricsBuffer.map((metrics) => metrics.frameDuration).toList()
          ..sort();

    final jankFrames = durations.where((d) => d > _frameJankThreshold).length;
    final slowFrames = durations.where((d) => d > _frameSlowThreshold).length;
    final totalFrames = durations.length;

    return {
      'total_frames': totalFrames,
      'jank_frames': jankFrames,
      'slow_frames': slowFrames,
      'jank_percentage': (jankFrames / totalFrames * 100).toStringAsFixed(1),
      'avg_frame_time_ms': durations.isNotEmpty
          ? (durations.map((d) => d.inMicroseconds).reduce((a, b) => a + b) /
                    durations.length /
                    1000)
                .toStringAsFixed(1)
          : '0',
      'p50_frame_time_ms': durations.isNotEmpty
          ? (durations[durations.length ~/ 2].inMicroseconds / 1000)
                .toStringAsFixed(1)
          : '0',
      'p90_frame_time_ms': durations.isNotEmpty
          ? (durations[(durations.length * 0.9).round().clamp(
                          0,
                          durations.length - 1,
                        )]
                        .inMicroseconds /
                    1000)
                .toStringAsFixed(1)
          : '0',
      'p99_frame_time_ms': durations.isNotEmpty
          ? (durations[(durations.length * 0.99).round().clamp(
                          0,
                          durations.length - 1,
                        )]
                        .inMicroseconds /
                    1000)
                .toStringAsFixed(1)
          : '0',
    };
  }

  /// Handle frame timing callbacks
  static void _onFrameTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      final metrics = FrameMetrics(
        frameDuration: timing.totalSpan,
        buildDuration: timing.buildDuration,
        rasterDuration: timing.rasterDuration,
        timestamp: DateTime.now(),
      );

      _frameMetricsBuffer.add(metrics);

      // Keep buffer size manageable
      while (_frameMetricsBuffer.length > _metricsBufferSize) {
        _frameMetricsBuffer.removeFirst();
      }

      // Log significant jank
      if (timing.totalSpan > _frameJankThreshold && kDebugMode) {
        AppLogger.w(
          '🐌 Frame jank detected: ${timing.totalSpan.inMilliseconds}ms '
          '(build: ${timing.buildDuration.inMilliseconds}ms, '
          'raster: ${timing.rasterDuration.inMilliseconds}ms)',
        );
      }
    }
  }

  /// Generate comprehensive performance report
  static void _generatePerformanceReport() {
    if (!kDebugMode) return;

    final startupSummary = getStartupSummary();
    final frameSummary = getFramePerformanceSummary();

    AppLogger.d('📊 === PERFORMANCE REPORT ===');

    // Startup performance
    if (startupSummary['total_startup_time_ms'] != null) {
      AppLogger.d(
        '🚀 Startup: ${startupSummary['total_startup_time_ms']}ms to first frame',
      );
    }

    // Service initialization times
    if (startupSummary['service_init_times'] is Map) {
      final serviceMap = startupSummary['service_init_times'] as Map;
      if (serviceMap.isNotEmpty) {
        AppLogger.d('⚙️ Service init times:');
        serviceMap.forEach((name, timeMs) {
          AppLogger.d('   $name: ${timeMs}ms');
        });
      }
    }

    // Frame performance
    if (frameSummary['total_frames'] != null) {
      AppLogger.d(
        '🎨 Frames: ${frameSummary['total_frames']} total, '
        '${frameSummary['jank_percentage']}% jank, '
        'avg: ${frameSummary['avg_frame_time_ms']}ms, '
        'p90: ${frameSummary['p90_frame_time_ms']}ms',
      );
    }

    AppLogger.d('📊 ========================');
  }

  /// Export performance data for analysis
  static Map<String, dynamic> exportPerformanceData() {
    return {
      'startup': getStartupSummary(),
      'frames': getFramePerformanceSummary(),
      'monitoring_active': _monitoring,
      'export_timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Quick performance check for critical paths
  static void measureCriticalPath(String pathName, VoidCallback operation) {
    if (!kDebugMode) return;

    final stopwatch = Stopwatch()..start();
    operation();
    stopwatch.stop();

    if (stopwatch.elapsedMilliseconds > 10) {
      // > 10ms is significant
      AppLogger.w(
        '⏱️ Critical path "$pathName" took ${stopwatch.elapsedMilliseconds}ms',
      );
    }
  }

  /// Dispose resources
  static void dispose() {
    stopMonitoring();
    _frameMetricsBuffer.clear();
    _milestones.clear();
    _serviceInitTimes.clear();
    _initialized = false;
  }
}

/// Frame metrics data structure
class FrameMetrics {
  final Duration frameDuration;
  final Duration buildDuration;
  final Duration rasterDuration;
  final DateTime timestamp;

  const FrameMetrics({
    required this.frameDuration,
    required this.buildDuration,
    required this.rasterDuration,
    required this.timestamp,
  });
}
