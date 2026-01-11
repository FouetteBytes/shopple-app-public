import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shopple/utils/app_logger.dart';
import 'package:shopple/services/analytics/enhanced_search_analytics_service.dart';
import 'package:shopple/services/user/user_search_service.dart';
import 'package:shopple/services/ai/quick_prompt_service.dart';
import 'package:shopple/debug/frame_timing_logger.dart';
import 'package:shopple/config/runtime_toggles.dart';
import 'package:shopple/services/performance/enhanced_performance_monitor.dart';
import 'package:shopple/services/media/profile_picture_service.dart';
import 'package:shopple/services/performance/firebase_realtime_database_optimizer.dart';
import 'package:shopple/services/core/resilient_network_service.dart';
import 'package:shopple/services/cache/offline_search_cache.dart';
import 'package:shopple/services/budget/budget_alert_service.dart';

/// 🚀 STARTUP OPTIMIZATION SERVICE
///
/// Manages progressive initialization of heavy services to prevent
/// main thread blocking and frame drops during app startup.
///
/// Features:
/// - Priority-based service loading
/// - Staggered initialization timing
/// - Background task scheduling
/// - Performance monitoring integration
class StartupOptimizationService {
  static bool _initialized = false;
  static final Map<String, bool> _serviceStatus = {};
  static final List<Timer> _activeTimers = [];

  /// Initialize progressive startup optimization
  /// Call this from main.dart after first frame renders
  static void initializeProgressiveStartup() {
    if (_initialized) return;
    _initialized = true;

    if (kDebugMode) {
      AppLogger.d(
        '🚀 StartupOptimization: Beginning progressive initialization',
      );
    }

    // Initialize enhanced performance monitoring
    EnhancedPerformanceMonitor.initialize();
    EnhancedPerformanceMonitor.recordMilestone('startup_optimization_begin');

    _scheduleServiceInitialization();
  }

  /// Schedule services in priority order with optimal timing
  static void _scheduleServiceInitialization() {
    // PHASE 1: Critical lightweight services (immediate)
    _initializePriority1Services();

    // PHASE 2: Analytics services (100ms delay)
    _scheduleDelayed('analytics', Duration(milliseconds: 100), () {
      _initializePriority2Services();
    });

    // PHASE 3: Search optimization (500ms delay)
    _scheduleDelayed('search_optimization', Duration(milliseconds: 500), () {
      _initializePriority3Services();
    });

    // PHASE 4: Performance monitoring (750ms delay)
    _scheduleDelayed('performance_monitoring', Duration(milliseconds: 750), () {
      _initializePriority4Services();
    });

    // PHASE 5: Background optimizations (1.5s delay)
    _scheduleDelayed('background_tasks', Duration(milliseconds: 1500), () {
      _initializePriority5Services();
    });
  }

  /// PHASE 1: Critical lightweight services
  static void _initializePriority1Services() {
    try {
      final stopwatch = Stopwatch()..start();

      // Initialize resilient network service first
      ResilientNetworkService.instance.initialize();
      _serviceStatus['resilient_network'] = true;

      // Initialize session tracking (lightweight)
      EnhancedSearchAnalyticsService.initializeSession();
      _serviceStatus['analytics_session'] = true;

      // Pre-warm quick cards cache (already optimized)
      QuickPromptService.warmCacheForCurrentUser();
      _serviceStatus['quick_cards'] = true;

      stopwatch.stop();
      EnhancedPerformanceMonitor.recordServiceInit(
        'priority_1_services',
        stopwatch.elapsed,
      );
      EnhancedPerformanceMonitor.recordMilestone('phase_1_complete');

      if (kDebugMode) {
        AppLogger.d(
          '✅ Phase 1 services initialized (resilient network, analytics session, quick cards)',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.e('❌ Phase 1 initialization error: $e');
      }
    }
  }

  /// PHASE 2: Analytics and Notification services
  static void _initializePriority2Services() {
    try {
      // Additional analytics initialization if needed
      // (Most analytics are already lightweight)
      _serviceStatus['analytics_full'] = true;

      // Initialize budget alert service (in-app toasts)
      _initializeBudgetAlerts();

      if (kDebugMode) {
        AppLogger.d('✅ Phase 2 services initialized (analytics, notifications)');
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.e('❌ Phase 2 initialization error: $e');
      }
    }
  }

  /// Initialize budget alert service (in-app toasts only)
  static void _initializeBudgetAlerts() {
    try {
      // Initialize budget alert monitoring (uses Fluttertoast)
      BudgetAlertService.instance.initialize();
      _serviceStatus['budget_alerts'] = true;

      if (kDebugMode) {
        AppLogger.d('🔔 Budget alert service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.e('⚠️ Budget alert initialization error: $e');
      }
      _serviceStatus['budget_alerts'] = false;
    }
  }

  /// PHASE 3: Search optimization (heaviest service)
  static void _initializePriority3Services() {
    try {
      final stopwatch = Stopwatch()..start();

      // Initialize offline search cache for resilient search
      OfflineSearchCache.instance.initialize();
      _serviceStatus['offline_search_cache'] = true;

      // Initialize search optimizations (connection warming, caching)
      UserSearchService.initializeSearchOptimizations();
      _serviceStatus['search_optimization'] = true;

      stopwatch.stop();
      EnhancedPerformanceMonitor.recordServiceInit(
        'search_optimization',
        stopwatch.elapsed,
      );
      EnhancedPerformanceMonitor.recordMilestone('phase_3_complete');

      if (kDebugMode) {
        AppLogger.d('✅ Phase 3 services initialized (offline cache, search optimization)');
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.e('❌ Phase 3 initialization error: $e');
      }
    }
  }

  /// PHASE 4: Performance monitoring
  static void _initializePriority4Services() {
    try {
      final stopwatch = Stopwatch()..start();

      // Start frame timing monitoring if enabled
      if (RuntimeToggles.instance.logFrameTimings.value) {
        FrameTimingLogger.start();
        EnhancedPerformanceMonitor.startMonitoring();
        _serviceStatus['frame_timing'] = true;
      }

      stopwatch.stop();
      EnhancedPerformanceMonitor.recordServiceInit(
        'performance_monitoring',
        stopwatch.elapsed,
      );
      EnhancedPerformanceMonitor.recordMilestone('phase_4_complete');

      if (kDebugMode) {
        AppLogger.d('✅ Phase 4 services initialized (performance monitoring)');
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.e('❌ Phase 4 initialization error: $e');
      }
    }
  }

  /// PHASE 5: Background optimization tasks and asset preloading
  static void _initializePriority5Services() {
    try {
      // Background asset preloading (moved from main.dart to prevent startup blocking)
      _initializeAssetPreloadingInBackground();

      // Initialize Firebase Realtime Database with optimizations
      _initializeFirebaseRealtimeDatabaseInBackground();

      // Any additional background optimization tasks
      _serviceStatus['background_optimization'] = true;

      if (kDebugMode) {
        AppLogger.d(
          '✅ Phase 5 services initialized (background tasks, asset preloading, Firebase optimizations)',
        );
        _logInitializationSummary();
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.e('❌ Phase 5 initialization error: $e');
      }
    }
  }

  /// Initialize Firebase Realtime Database with optimizations in background
  static void _initializeFirebaseRealtimeDatabaseInBackground() {
    scheduleMicrotask(() async {
      try {
        // Wait for app to stabilize before initializing database connections
        await Future.delayed(const Duration(milliseconds: 1000));

        await FirebaseRealtimeDatabaseOptimizer.initializeOptimizedConnection();
        _serviceStatus['firebase_realtime_db'] = true;

        if (kDebugMode) {
          AppLogger.d('✅ Firebase Realtime Database optimized in background');
        }
      } catch (e) {
        if (kDebugMode) {
          AppLogger.w(
            '⚠️ Firebase Realtime Database optimization failed (non-critical): $e',
          );
        }
        _serviceStatus['firebase_realtime_db'] = false;
      }
    });
  }

  /// Initialize asset preloading in background
  static void _initializeAssetPreloadingInBackground() {
    // Store context reference for asset preloading
    scheduleMicrotask(() async {
      try {
        // Wait a bit for app to fully stabilize
        await Future.delayed(const Duration(milliseconds: 500));

        // Get the current context safely
        final context = Get.context;
        if (context != null && context.mounted) {
          await ProfilePictureService.preloadMemojiAssets(
            context,
            batchSize: 2, // Smaller batches to reduce frame impact
            batchDelay: const Duration(
              milliseconds: 50,
            ), // Longer delays between batches
          );
          _serviceStatus['asset_preloading'] = true;

          if (kDebugMode) {
            AppLogger.d('✅ Asset preloading completed in background');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          AppLogger.w('⚠️ Asset preloading failed (non-critical): $e');
        }
        _serviceStatus['asset_preloading'] = false;
      }
    });
  }

  /// Schedule a delayed service initialization
  static void _scheduleDelayed(
    String name,
    Duration delay,
    VoidCallback callback,
  ) {
    final timer = Timer(delay, () {
      try {
        callback();
      } catch (e) {
        if (kDebugMode) {
          AppLogger.e('Delayed initialization error for $name: $e');
        }
      }
    });
    _activeTimers.add(timer);
  }

  /// Log initialization summary for debugging
  static void _logInitializationSummary() {
    if (!kDebugMode) return;

    AppLogger.d('🏁 StartupOptimization: Progressive initialization complete');
    AppLogger.d('📊 Service Status:');
    _serviceStatus.forEach((service, status) {
      AppLogger.d('   $service: ${status ? "✅" : "❌"}');
    });
  }

  /// Get current service initialization status
  static Map<String, bool> getServiceStatus() {
    return Map.from(_serviceStatus);
  }

  /// Check if a specific service is initialized
  static bool isServiceInitialized(String serviceName) {
    return _serviceStatus[serviceName] ?? false;
  }

  /// Clean up resources (call on app dispose if needed)
  static void dispose() {
    for (final timer in _activeTimers) {
      timer.cancel();
    }
    _activeTimers.clear();
    _serviceStatus.clear();
    _initialized = false;
  }
}
