import 'package:flutter/foundation.dart';
import 'feature_flags.dart';
import '../debug/frame_timing_logger.dart';

class RuntimeToggles {
  static final RuntimeToggles instance = RuntimeToggles._();
  RuntimeToggles._();

  final ValueNotifier<bool> showPerformanceOverlay = ValueNotifier(
    FeatureFlags.showPerformanceOverlay,
  );
  final ValueNotifier<bool> logFrameTimings = ValueNotifier(
    FeatureFlags.logFrameTimings,
  );
  final ValueNotifier<bool> disableOnboardingPrecache = ValueNotifier(
    FeatureFlags.disableOnboardingPrecache,
  );

  void togglePerfOverlay() =>
      showPerformanceOverlay.value = !showPerformanceOverlay.value;
  void toggleFrameTimings() {
    final newVal = !logFrameTimings.value;
    logFrameTimings.value = newVal;
    if (newVal) {
      FrameTimingLogger.start();
    } else {
      FrameTimingLogger.stop();
    }
  }

  void toggleDisablePrecache() =>
      disableOnboardingPrecache.value = !disableOnboardingPrecache.value;
}
