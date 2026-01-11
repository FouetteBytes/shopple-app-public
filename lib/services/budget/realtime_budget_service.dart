import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shopple/models/budget/budget_cadence.dart';
import 'package:shopple/models/shopping_lists/shopping_list_item_model.dart';
import 'package:shopple/models/shopping_lists/shopping_list_model.dart';
import 'package:shopple/utils/app_logger.dart';

/// Real-time budget tracking service with Firestore listeners.
/// Provides live spending updates, intelligent aggregation, and budget alerts.
class RealtimeBudgetService {
  RealtimeBudgetService._();
  static final RealtimeBudgetService instance = RealtimeBudgetService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, StreamSubscription<QuerySnapshot>> _listItemListeners = {};
  final Map<String, StreamSubscription<DocumentSnapshot>> _listListeners = {};
  StreamSubscription<QuerySnapshot>? _userListsListener;

  /// Current user's spending state
  final ValueNotifier<RealtimeBudgetState> stateNotifier =
      ValueNotifier(const RealtimeBudgetState.initial());

  /// Stream controller for budget updates
  final _budgetStreamController = StreamController<RealtimeSpendingData>.broadcast();
  
  /// Stream of budget updates for alert monitoring
  Stream<RealtimeSpendingData> get budgetStream => _budgetStreamController.stream;

  /// Per-list spending streams
  final Map<String, ValueNotifier<ListSpendingState>> _listStates = {};

  /// Aggregated spending data
  RealtimeSpendingData _spendingData = RealtimeSpendingData.empty;
  String? _currentUserId;
  bool _initialized = false;

  /// Initialize the real-time budget tracking for a user
  Future<void> initialize(String userId) async {
    if (_initialized && _currentUserId == userId) return;

    await dispose();
    _currentUserId = userId;
    _initialized = true;

    AppLogger.d('RealtimeBudgetService: Initializing for user $userId');

    try {
      // Listen to user's shopping lists
      _userListsListener = _firestore
          .collection('shopping_lists')
          .where('memberIds', arrayContains: userId)
          .where('status', isEqualTo: 'active')
          .snapshots()
          .listen(_handleListsUpdate, onError: _handleError);
    } catch (e) {
      AppLogger.e('RealtimeBudgetService: Failed to initialize', error: e);
      stateNotifier.value = RealtimeBudgetState.error(e.toString());
    }
  }

  /// Get a notifier for a specific list's spending
  ValueNotifier<ListSpendingState> getListSpendingNotifier(String listId) {
    return _listStates.putIfAbsent(
      listId,
      () => ValueNotifier(const ListSpendingState.loading()),
    );
  }

  void _handleListsUpdate(QuerySnapshot snapshot) {
    final lists = snapshot.docs.map((doc) {
      return ShoppingList.fromFirestore(doc);
    }).toList();

    // Active list IDs for listener reconciliation
    final activeListIds = lists.map((l) => l.id).toSet();

    // Remove listeners for lists no longer active
    final toRemove = _listItemListeners.keys
        .where((id) => !activeListIds.contains(id))
        .toList();
    for (final listId in toRemove) {
      _listItemListeners[listId]?.cancel();
      _listItemListeners.remove(listId);
      _listListeners[listId]?.cancel();
      _listListeners.remove(listId);
      _listStates.remove(listId);
    }

    // Add listeners for new lists
    for (final list in lists) {
      if (!_listItemListeners.containsKey(list.id)) {
        _subscribeToList(list);
      }
    }

    // Update aggregated spending
    _recalculateAggregates(lists);
  }

  void _subscribeToList(ShoppingList list) {
    // Listen to list document for budget changes
    _listListeners[list.id] = _firestore
        .collection('shopping_lists')
        .doc(list.id)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        final updatedList = ShoppingList.fromFirestore(doc);
        _updateListState(updatedList);
      }
    });

    // Listen to items for spending changes
    _listItemListeners[list.id] = _firestore
        .collection('shopping_lists')
        .doc(list.id)
        .collection('items')
        .snapshots()
        .listen((itemsSnapshot) {
      final items = itemsSnapshot.docs
          .map((doc) => ShoppingListItem.fromFirestore(doc))
          .toList();
      _handleItemsUpdate(list.id, items);
    });
  }

  void _updateListState(ShoppingList list) {
    final notifier = _listStates[list.id];
    if (notifier == null) return;

    final currentState = notifier.value;
    if (currentState.status == ListSpendingStatus.ready) {
      notifier.value = currentState.copyWith(
        budget: list.budgetLimit,
        cadence: list.budgetCadence,
      );
    }
  }

  void _handleItemsUpdate(String listId, List<ShoppingListItem> items) {
    final now = DateTime.now();
    final completedItems = items.where((i) => i.isCompleted).toList();

    // Calculate spending metrics
    double totalSpent = 0;
    double todaySpent = 0;
    double weekSpent = 0;
    double monthSpent = 0;
    final categorySpend = <String, double>{};

    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = _startOfWeek(now);
    final monthStart = DateTime(now.year, now.month, 1);

    for (final item in completedItems) {
      final itemTotal = _safeTotalPrice(item);
      final eventDate = item.completedAt ?? item.updatedAt;

      totalSpent += itemTotal;

      // Time-based aggregation
      if (!eventDate.isBefore(todayStart)) {
        todaySpent += itemTotal;
      }
      if (!eventDate.isBefore(weekStart)) {
        weekSpent += itemTotal;
      }
      if (!eventDate.isBefore(monthStart)) {
        monthSpent += itemTotal;
      }

      // Category aggregation
      final cat = item.category.isEmpty ? 'other' : item.category;
      categorySpend[cat] = (categorySpend[cat] ?? 0) + itemTotal;
    }

    // Update list state
    final notifier = _listStates.putIfAbsent(
      listId,
      () => ValueNotifier(const ListSpendingState.loading()),
    );

    notifier.value = ListSpendingState.ready(
      listId: listId,
      totalSpent: totalSpent,
      todaySpent: todaySpent,
      weekSpent: weekSpent,
      monthSpent: monthSpent,
      completedCount: completedItems.length,
      totalCount: items.length,
      categorySpend: categorySpend,
      lastUpdated: now,
    );

    // Trigger aggregate recalculation
    _triggerAggregateUpdate();
  }

  Timer? _aggregateDebounce;
  void _triggerAggregateUpdate() {
    _aggregateDebounce?.cancel();
    _aggregateDebounce = Timer(const Duration(milliseconds: 150), () async {
      // Get all current lists
      final userId = _currentUserId;
      if (userId == null) return;

      try {
        final snapshot = await _firestore
            .collection('shopping_lists')
            .where('memberIds', arrayContains: userId)
            .where('status', isEqualTo: 'active')
            .get();

        final lists = snapshot.docs
            .map((doc) => ShoppingList.fromFirestore(doc))
            .toList();

        _recalculateAggregates(lists);
      } catch (e) {
        AppLogger.w('RealtimeBudgetService: Failed to recalculate aggregates: $e');
      }
    });
  }

  void _recalculateAggregates(List<ShoppingList> lists) {
    final now = DateTime.now();

    double totalBudget = 0;
    double totalSpent = 0;
    double todaySpent = 0;
    double weekSpent = 0;
    double monthSpent = 0;
    int activeBudgets = 0;
    final categorySpend = <String, double>{};
    final alerts = <BudgetAlert>[];

    for (final list in lists) {
      final listState = _listStates[list.id]?.value;
      if (listState == null || listState.status != ListSpendingStatus.ready) {
        continue;
      }

      // Aggregate list spending
      totalSpent += listState.totalSpent;
      todaySpent += listState.todaySpent;
      weekSpent += listState.weekSpent;
      monthSpent += listState.monthSpent;

      // Aggregate category spending
      for (final entry in listState.categorySpend.entries) {
        categorySpend[entry.key] = (categorySpend[entry.key] ?? 0) + entry.value;
      }

      // Check budget alerts
      if (list.budgetLimit > 0) {
        totalBudget += list.budgetLimit;
        activeBudgets++;

        final utilization = listState.totalSpent / list.budgetLimit;
        if (utilization >= 1.0) {
          alerts.add(BudgetAlert(
            listId: list.id,
            listName: list.name,
            type: BudgetAlertType.exceeded,
            utilization: utilization,
            message:
                '${list.name} has exceeded budget by ${_formatPercent(utilization - 1.0)}',
          ));
        } else if (utilization >= 0.9) {
          alerts.add(BudgetAlert(
            listId: list.id,
            listName: list.name,
            type: BudgetAlertType.nearLimit,
            utilization: utilization,
            message: '${list.name} is at ${_formatPercent(utilization)} of budget',
          ));
        } else if (utilization >= 0.75) {
          alerts.add(BudgetAlert(
            listId: list.id,
            listName: list.name,
            type: BudgetAlertType.warning,
            utilization: utilization,
            message:
                '${list.name} has used ${_formatPercent(utilization)} of budget',
          ));
        }
      }
    }

    // Calculate predictions
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dayOfMonth = now.day;
    final projectedMonthSpend = dayOfMonth > 0
        ? (monthSpent / dayOfMonth) * daysInMonth
        : monthSpent;

    // Average daily spending this month
    final avgDailySpend = dayOfMonth > 0 ? monthSpent / dayOfMonth : 0.0;

    _spendingData = RealtimeSpendingData(
      totalBudget: totalBudget,
      totalSpent: totalSpent,
      todaySpent: todaySpent,
      weekSpent: weekSpent,
      monthSpent: monthSpent,
      projectedMonthSpend: projectedMonthSpend,
      avgDailySpend: avgDailySpend,
      activeBudgets: activeBudgets,
      categorySpend: Map.unmodifiable(categorySpend),
      alerts: List.unmodifiable(alerts),
      lastUpdated: now,
    );

    stateNotifier.value = RealtimeBudgetState.ready(_spendingData);
    
    // Notify budget stream for alert monitoring
    _budgetStreamController.add(_spendingData);
  }

  void _handleError(Object error) {
    AppLogger.e('RealtimeBudgetService: Stream error', error: error);
    stateNotifier.value = RealtimeBudgetState.error(error.toString());
  }

  double _safeTotalPrice(ShoppingListItem item) {
    final quantity = item.quantity <= 0 ? 1 : item.quantity;
    final price = item.estimatedPrice.isFinite ? item.estimatedPrice : 0.0;
    final safePrice = price < 0 ? 0.0 : price;
    return safePrice * quantity;
  }

  static DateTime _startOfWeek(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  String _formatPercent(double value) => '${(value * 100).toStringAsFixed(0)}%';

  /// Get current spending data synchronously
  RealtimeSpendingData get currentSpending => _spendingData;

  /// Record a manual spending entry (for non-list purchases)
  Future<void> recordManualSpending({
    required double amount,
    required String category,
    String? description,
    DateTime? date,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final now = DateTime.now();
    final spendingDate = date ?? now;

    try {
      await _firestore.collection('users').doc(userId).collection('manual_spending').add({
        'amount': amount,
        'category': category,
        'description': description ?? '',
        'date': Timestamp.fromDate(spendingDate),
        'createdAt': Timestamp.fromDate(now),
      });

      AppLogger.d('RealtimeBudgetService: Recorded manual spending: $amount in $category');
    } catch (e) {
      AppLogger.e('RealtimeBudgetService: Failed to record manual spending', error: e);
      rethrow;
    }
  }

  /// Dispose all listeners
  Future<void> dispose() async {
    _aggregateDebounce?.cancel();
    _userListsListener?.cancel();
    for (final sub in _listItemListeners.values) {
      await sub.cancel();
    }
    _listItemListeners.clear();
    for (final sub in _listListeners.values) {
      await sub.cancel();
    }
    _listListeners.clear();
    _listStates.clear();
    _initialized = false;
    _currentUserId = null;
    _spendingData = RealtimeSpendingData.empty;
    stateNotifier.value = const RealtimeBudgetState.initial();
    AppLogger.d('RealtimeBudgetService: Disposed');
  }
}

// ============================================================================
// State classes
// ============================================================================

enum RealtimeBudgetStatus { initial, loading, ready, error }

class RealtimeBudgetState {
  const RealtimeBudgetState._(this.status, this.data, this.errorMessage);

  const RealtimeBudgetState.initial()
      : this._(RealtimeBudgetStatus.initial, null, null);
  const RealtimeBudgetState.loading()
      : this._(RealtimeBudgetStatus.loading, null, null);
  const RealtimeBudgetState.ready(RealtimeSpendingData data)
      : this._(RealtimeBudgetStatus.ready, data, null);
  const RealtimeBudgetState.error(String message)
      : this._(RealtimeBudgetStatus.error, null, message);

  final RealtimeBudgetStatus status;
  final RealtimeSpendingData? data;
  final String? errorMessage;

  bool get isReady => status == RealtimeBudgetStatus.ready;
}

class RealtimeSpendingData {
  const RealtimeSpendingData({
    required this.totalBudget,
    required this.totalSpent,
    required this.todaySpent,
    required this.weekSpent,
    required this.monthSpent,
    required this.projectedMonthSpend,
    required this.avgDailySpend,
    required this.activeBudgets,
    required this.categorySpend,
    required this.alerts,
    required this.lastUpdated,
  });

  static const RealtimeSpendingData empty = RealtimeSpendingData(
    totalBudget: 0,
    totalSpent: 0,
    todaySpent: 0,
    weekSpent: 0,
    monthSpent: 0,
    projectedMonthSpend: 0,
    avgDailySpend: 0,
    activeBudgets: 0,
    categorySpend: {},
    alerts: [],
    lastUpdated: null,
  );

  final double totalBudget;
  final double totalSpent;
  final double todaySpent;
  final double weekSpent;
  final double monthSpent;
  final double projectedMonthSpend;
  final double avgDailySpend;
  final int activeBudgets;
  final Map<String, double> categorySpend;
  final List<BudgetAlert> alerts;
  final DateTime? lastUpdated;

  double get remaining => totalBudget - totalSpent;
  double get utilization =>
      totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 2.0) : 0.0;
  bool get isOverBudget => totalBudget > 0 && totalSpent > totalBudget;
  
  /// Alert threshold (default 80%)
  double get alertThreshold => 0.8;
  
  /// Budget ID for tracking alerts
  String get budgetId => 'global';

  RealtimeSpendingData copyWith({
    double? totalBudget,
    double? totalSpent,
    double? todaySpent,
    double? weekSpent,
    double? monthSpent,
    double? projectedMonthSpend,
    double? avgDailySpend,
    int? activeBudgets,
    Map<String, double>? categorySpend,
    List<BudgetAlert>? alerts,
    DateTime? lastUpdated,
  }) {
    return RealtimeSpendingData(
      totalBudget: totalBudget ?? this.totalBudget,
      totalSpent: totalSpent ?? this.totalSpent,
      todaySpent: todaySpent ?? this.todaySpent,
      weekSpent: weekSpent ?? this.weekSpent,
      monthSpent: monthSpent ?? this.monthSpent,
      projectedMonthSpend: projectedMonthSpend ?? this.projectedMonthSpend,
      avgDailySpend: avgDailySpend ?? this.avgDailySpend,
      activeBudgets: activeBudgets ?? this.activeBudgets,
      categorySpend: categorySpend ?? this.categorySpend,
      alerts: alerts ?? this.alerts,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// ============================================================================
// List-level spending state
// ============================================================================

enum ListSpendingStatus { loading, ready, error }

class ListSpendingState {
  const ListSpendingState._({
    required this.status,
    this.listId,
    this.totalSpent = 0,
    this.todaySpent = 0,
    this.weekSpent = 0,
    this.monthSpent = 0,
    this.budget = 0,
    this.cadence = BudgetCadence.none,
    this.completedCount = 0,
    this.totalCount = 0,
    this.categorySpend = const {},
    this.lastUpdated,
    this.errorMessage,
  });

  const ListSpendingState.loading()
      : this._(status: ListSpendingStatus.loading);

  const ListSpendingState.ready({
    required String listId,
    required double totalSpent,
    required double todaySpent,
    required double weekSpent,
    required double monthSpent,
    double budget = 0,
    BudgetCadence cadence = BudgetCadence.none,
    required int completedCount,
    required int totalCount,
    required Map<String, double> categorySpend,
    DateTime? lastUpdated,
  }) : this._(
          status: ListSpendingStatus.ready,
          listId: listId,
          totalSpent: totalSpent,
          todaySpent: todaySpent,
          weekSpent: weekSpent,
          monthSpent: monthSpent,
          budget: budget,
          cadence: cadence,
          completedCount: completedCount,
          totalCount: totalCount,
          categorySpend: categorySpend,
          lastUpdated: lastUpdated,
        );

  const ListSpendingState.error(String message)
      : this._(status: ListSpendingStatus.error, errorMessage: message);

  final ListSpendingStatus status;
  final String? listId;
  final double totalSpent;
  final double todaySpent;
  final double weekSpent;
  final double monthSpent;
  final double budget;
  final BudgetCadence cadence;
  final int completedCount;
  final int totalCount;
  final Map<String, double> categorySpend;
  final DateTime? lastUpdated;
  final String? errorMessage;

  double get utilization =>
      budget > 0 ? (totalSpent / budget).clamp(0.0, 2.0) : 0.0;
  bool get isOverBudget => budget > 0 && totalSpent > budget;
  double get remaining => budget - totalSpent;

  ListSpendingState copyWith({
    ListSpendingStatus? status,
    String? listId,
    double? totalSpent,
    double? todaySpent,
    double? weekSpent,
    double? monthSpent,
    double? budget,
    BudgetCadence? cadence,
    int? completedCount,
    int? totalCount,
    Map<String, double>? categorySpend,
    DateTime? lastUpdated,
    String? errorMessage,
  }) {
    return ListSpendingState._(
      status: status ?? this.status,
      listId: listId ?? this.listId,
      totalSpent: totalSpent ?? this.totalSpent,
      todaySpent: todaySpent ?? this.todaySpent,
      weekSpent: weekSpent ?? this.weekSpent,
      monthSpent: monthSpent ?? this.monthSpent,
      budget: budget ?? this.budget,
      cadence: cadence ?? this.cadence,
      completedCount: completedCount ?? this.completedCount,
      totalCount: totalCount ?? this.totalCount,
      categorySpend: categorySpend ?? this.categorySpend,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ============================================================================
// Budget alerts
// ============================================================================

enum BudgetAlertType { warning, nearLimit, exceeded }

class BudgetAlert {
  const BudgetAlert({
    required this.listId,
    required this.listName,
    required this.type,
    required this.utilization,
    required this.message,
  });

  final String listId;
  final String listName;
  final BudgetAlertType type;
  final double utilization;
  final String message;
}
