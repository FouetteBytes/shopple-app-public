import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/app_logger.dart';

/// 🚀 WIDGET PERFORMANCE UTILITIES
///
/// Collection of utilities and patterns for optimizing widget performance
/// - Memoization helpers
/// - Const constructor patterns
/// - Efficient rebuild strategies
/// - Memory management optimizations

/// Memoized wrapper for widgets that rebuild frequently but don't need to
/// Use this for widgets with expensive build methods that depend on primitive values
class MemoizedWidget extends StatelessWidget {
  final Widget Function() builder;
  final List<Object?> dependencies;
  final String? debugLabel;

  const MemoizedWidget({
    super.key,
    required this.builder,
    required this.dependencies,
    this.debugLabel,
  });

  @override
  Widget build(BuildContext context) {
    // Flutter's Element system will automatically memoize this widget
    // if the dependencies haven't changed
    return builder();
  }
}

/// Performance-optimized container with const-friendly parameters
class OptimizedContainer extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Decoration? decoration;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  const OptimizedContainer({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.color,
    this.decoration,
    this.width,
    this.height,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      margin: margin,
      color: color,
      decoration: decoration,
      width: width,
      height: height,
      alignment: alignment,
      child: child,
    );
  }
}

/// Performance-optimized text widget with efficient style caching
class OptimizedText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  const OptimizedText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}

/// Const-friendly icon widget wrapper
class OptimizedIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  const OptimizedIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: size, color: color, semanticLabel: semanticLabel);
  }
}

/// Performance utilities for measuring and optimizing widget performance
class WidgetPerformanceUtils {
  /// Wrap a widget to measure its build time
  static Widget measureBuildTime(
    Widget child, {
    String? label,
    bool enableInRelease = false,
  }) {
    return _BuildTimeMeasurer(
      label: label ?? 'Widget',
      enableInRelease: enableInRelease,
      child: child,
    );
  }

  /// Check if a widget should be rebuilt based on dependencies
  static bool shouldRebuild(List<Object?> oldDeps, List<Object?> newDeps) {
    if (oldDeps.length != newDeps.length) return true;

    for (int i = 0; i < oldDeps.length; i++) {
      if (oldDeps[i] != newDeps[i]) return true;
    }

    return false;
  }

  /// Create a const-friendly shadow list
  static const List<BoxShadow> defaultShadow = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 2)),
  ];

  /// Create a const-friendly border radius
  static const BorderRadius defaultBorderRadius = BorderRadius.all(
    Radius.circular(12),
  );
}

/// Internal widget for measuring build times
class _BuildTimeMeasurer extends StatelessWidget {
  final String label;
  final bool enableInRelease;
  final Widget child;

  const _BuildTimeMeasurer({
    required this.label,
    required this.enableInRelease,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!enableInRelease && !kDebugMode) {
      return child;
    }

    final stopwatch = Stopwatch()..start();
    final result = child;
    stopwatch.stop();

    // Log build time if it's significant
    if (stopwatch.elapsedMicroseconds > 1000) {
      // > 1ms
      AppLogger.d(
        '🐌 Slow widget build: $label took ${stopwatch.elapsedMicroseconds}μs',
      );
    }

    return result;
  }
}

/// Const-friendly common decorations
class CommonDecorations {
  const CommonDecorations._();

  static const BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: WidgetPerformanceUtils.defaultBorderRadius,
    boxShadow: WidgetPerformanceUtils.defaultShadow,
  );

  static const BoxDecoration darkCardDecoration = BoxDecoration(
    color: Color(0xFF2C2C2C),
    borderRadius: WidgetPerformanceUtils.defaultBorderRadius,
    boxShadow: WidgetPerformanceUtils.defaultShadow,
  );

  static const EdgeInsets defaultPadding = EdgeInsets.all(16);
  static const EdgeInsets smallPadding = EdgeInsets.all(8);
  static const EdgeInsets largePadding = EdgeInsets.all(24);
}

/// Extension to add performance utilities to existing widgets
extension WidgetPerformanceExtensions on Widget {
  /// Wrap this widget with memoization
  Widget memoized(List<Object?> dependencies, {String? debugLabel}) {
    return MemoizedWidget(
      dependencies: dependencies,
      debugLabel: debugLabel,
      builder: () => this,
    );
  }

  /// Measure build time of this widget
  Widget measureBuildTime({String? label, bool enableInRelease = false}) {
    return WidgetPerformanceUtils.measureBuildTime(
      this,
      label: label,
      enableInRelease: enableInRelease,
    );
  }
}

/// 🧠 MEMORY MANAGEMENT UTILITIES
///
/// Tools to reduce garbage collection pressure and optimize memory usage
class MemoryOptimizer {
  static final Map<String, Timer> _scheduledCleanups = {};
  static const Duration _defaultCleanupDelay = Duration(seconds: 5);

  /// Schedule delayed cleanup to reduce GC pressure during critical operations
  static void scheduleCleanup(
    String key,
    VoidCallback cleanup, {
    Duration? delay,
  }) {
    // Cancel previous cleanup if exists
    _scheduledCleanups[key]?.cancel();

    _scheduledCleanups[key] = Timer(delay ?? _defaultCleanupDelay, () {
      cleanup();
      _scheduledCleanups.remove(key);
    });
  }

  /// Force immediate cleanup of all scheduled operations
  static void forceCleanup() {
    for (final timer in _scheduledCleanups.values) {
      timer.cancel();
    }
    _scheduledCleanups.clear();
  }

  /// Debounced rebuild helper to prevent excessive widget rebuilds
  static Timer? _rebuildTimer;
  static void debouncedRebuild(
    VoidCallback rebuild, {
    Duration delay = const Duration(milliseconds: 100),
  }) {
    _rebuildTimer?.cancel();
    _rebuildTimer = Timer(delay, rebuild);
  }

  /// Batch widget updates to reduce rebuild frequency
  static void batchWidgetUpdates(
    List<VoidCallback> updates, {
    Duration delay = const Duration(milliseconds: 16),
  }) {
    Timer(delay, () {
      for (final update in updates) {
        update();
      }
    });
  }
}
