import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shopple/models/budget/budget_analytics_model.dart';
import 'package:shopple/services/budget/budget_analytics_service.dart';
import 'package:shopple/services/budget/realtime_budget_service.dart';
import 'package:shopple/services/budget/spending_insights_service.dart';
import 'package:shopple/services/shopping_lists/shopping_list_cache.dart';
import 'package:shopple/utils/app_logger.dart';

/// Enhanced budget analytics controller with real-time updates and intelligent insights.
class BudgetAnalyticsController extends ChangeNotifier {
  BudgetAnalyticsController({
    ShoppingListCache? listCache,
    BudgetAnalyticsService? analyticsService,
  }) : _listCache = listCache ?? ShoppingListCache.instance,
       _analyticsService = analyticsService ?? BudgetAnalyticsService();

  final ShoppingListCache _listCache;
  final BudgetAnalyticsService _analyticsService;
  final RealtimeBudgetService _realtimeService = RealtimeBudgetService.instance;
  final SpendingInsightsService _insightsService = SpendingInsightsService.instance;

  BudgetAnalyticsState _state = const BudgetAnalyticsState.idle();
  SpendingInsights? _insights;
  RealtimeSpendingData? _realtimeData;
  
  VoidCallback? _cacheListener;
  VoidCallback? _realtimeListener;
  Timer? _debounce;
  Timer? _insightsRefreshTimer;
  bool _initialized = false;

  BudgetAnalyticsState get state => _state;
  SpendingInsights? get insights => _insights;
  RealtimeSpendingData? get realtimeData => _realtimeData;

  /// Quick access to current spending for UI
  double get todaySpent => _realtimeData?.todaySpent ?? 0;
  double get weekSpent => _realtimeData?.weekSpent ?? 0;
  double get monthSpent => _realtimeData?.monthSpent ?? 0;
  double get totalBudget => _realtimeData?.totalBudget ?? 0;
  double get utilization => _realtimeData?.utilization ?? 0;
  bool get isOverBudget => _realtimeData?.isOverBudget ?? false;
  List<BudgetAlert> get alerts => _realtimeData?.alerts ?? [];

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    AppLogger.d('BudgetAnalyticsController: Initializing');

    // Initialize the list cache
    await _listCache.ensureSubscribed();

    // Initialize real-time budget tracking
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await _realtimeService.initialize(userId);
      
      // Listen to real-time budget updates
      _realtimeListener = _onRealtimeUpdate;
      _realtimeService.stateNotifier.addListener(_realtimeListener!);
    }

    // Listen to list changes for full snapshot refresh
    _cacheListener = _onListsChanged;
    _listCache.listenable.addListener(_cacheListener!);
    
    // Initial refresh
    await refresh();

    // Schedule periodic insights refresh (every 5 minutes)
    _insightsRefreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _refreshInsights(),
    );
  }

  /// Full refresh of analytics snapshot and insights
  Future<void> refresh() async {
    _setState(const BudgetAnalyticsState.loading());
    try {
      final lists = _listCache.current;
      if (lists.isEmpty) {
        _setState(BudgetAnalyticsState.ready(BudgetAnalyticsSnapshot.empty));
        _insights = SpendingInsights.empty;
        notifyListeners();
        return;
      }
      
      // Build analytics snapshot
      final snapshot = await _analyticsService.buildSnapshot(lists);
      _setState(BudgetAnalyticsState.ready(snapshot));
      
      // Generate insights in background (don't block UI)
      _refreshInsights();
    } catch (e) {
      AppLogger.e('BudgetAnalyticsController: Refresh failed', error: e);
      _setState(BudgetAnalyticsState.error(e.toString()));
    }
  }

  /// Refresh spending insights asynchronously
  Future<void> _refreshInsights() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final lists = _listCache.current;
      if (lists.isEmpty) return;

      final insights = await _insightsService.generateInsights(userId, lists);
      _insights = insights;
      notifyListeners();
      
      AppLogger.d('BudgetAnalyticsController: Insights refreshed');
    } catch (e) {
      AppLogger.w('BudgetAnalyticsController: Insights refresh failed: $e');
    }
  }

  void _onRealtimeUpdate() {
    final state = _realtimeService.stateNotifier.value;
    if (state.isReady && state.data != null) {
      _realtimeData = state.data;
      notifyListeners();
    }
  }

  void _onListsChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), refresh);
  }

  void _setState(BudgetAnalyticsState next) {
    if (_state == next) return;
    _state = next;
    notifyListeners();
  }

  /// Force refresh insights (called after budget changes)
  Future<void> refreshInsightsNow() async {
    await _refreshInsights();
  }

  /// Check if there are high-priority alerts or recommendations
  bool get hasHighPriorityItems {
    final hasAlerts = alerts.any((a) => a.type == BudgetAlertType.exceeded);
    final hasRecommendations = _insights?.hasHighPriorityItems ?? false;
    return hasAlerts || hasRecommendations;
  }

  /// Get summary text for quick display
  String get statusSummary {
    if (_realtimeData == null) return 'Loading...';
    
    if (isOverBudget) {
      return 'Over budget by Rs ${(_realtimeData!.totalSpent - _realtimeData!.totalBudget).toStringAsFixed(0)}';
    }
    
    if (totalBudget > 0) {
      return 'Rs ${_realtimeData!.remaining.toStringAsFixed(0)} remaining';
    }
    
    return 'Rs ${monthSpent.toStringAsFixed(0)} spent this month';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _insightsRefreshTimer?.cancel();
    if (_cacheListener != null) {
      _listCache.listenable.removeListener(_cacheListener!);
    }
    if (_realtimeListener != null) {
      _realtimeService.stateNotifier.removeListener(_realtimeListener!);
    }
    super.dispose();
  }
}

enum BudgetAnalyticsStatus { idle, loading, ready, error }

class BudgetAnalyticsState {
  const BudgetAnalyticsState._(this.status, this.snapshot, this.errorMessage);

  const BudgetAnalyticsState.idle()
    : this._(BudgetAnalyticsStatus.idle, null, null);
  const BudgetAnalyticsState.loading()
    : this._(BudgetAnalyticsStatus.loading, null, null);
  const BudgetAnalyticsState.ready(BudgetAnalyticsSnapshot snapshot)
    : this._(BudgetAnalyticsStatus.ready, snapshot, null);
  const BudgetAnalyticsState.error(String message)
    : this._(BudgetAnalyticsStatus.error, null, message);

  final BudgetAnalyticsStatus status;
  final BudgetAnalyticsSnapshot? snapshot;
  final String? errorMessage;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BudgetAnalyticsState &&
        other.status == status &&
        other.snapshot == snapshot &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(status, snapshot, errorMessage);
}
