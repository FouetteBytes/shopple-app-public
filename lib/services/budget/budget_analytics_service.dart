import 'dart:async';
import 'dart:math';
import 'package:shopple/models/budget/budget_analytics_model.dart';
import 'package:shopple/models/budget/budget_cadence.dart';
import 'package:shopple/models/budget/budget_period.dart';
import 'package:shopple/models/shopping_lists/shopping_list_item_model.dart';
import 'package:shopple/models/shopping_lists/shopping_list_model.dart';
import 'package:shopple/services/shopping_lists/shopping_list_service.dart';

class BudgetAnalyticsService {
  BudgetAnalyticsService({Duration? cacheTtl})
    : _cacheTtl = cacheTtl ?? const Duration(minutes: 5);

  final Duration _cacheTtl;
  final Map<String, _ItemCacheEntry> _itemCache = {};

  Future<BudgetAnalyticsSnapshot> buildSnapshot(
    List<ShoppingList> lists,
  ) async {
    if (lists.isEmpty) {
      return BudgetAnalyticsSnapshot.empty;
    }

    final now = DateTime.now();
    final weekStart = _startOfWeek(now);
    final monthStart = DateTime(now.year, now.month);

    final weeklyBuckets = <DateTime, double>{};
    final categorySpend = <String, double>{};
    final frequentMap = <String, _FrequentEntry>{};
    final listHealth = <ListBudgetHealth>[];

    double totalBudget = 0;
    double totalBudgetSpent = 0;
    double weekToDateSpend = 0;
    double monthToDateSpend = 0;
    int activeBudgets = 0;

    final relevantLists = lists
        .where((l) => l.status != ListStatus.archived)
        .toList();
    final itemFutures = relevantLists.map(_itemsForList).toList();
    final itemsPerList = await Future.wait(itemFutures);

    for (var i = 0; i < relevantLists.length; i++) {
      final list = relevantLists[i];
      final items = itemsPerList[i];
      final budget = list.budgetLimit < 0 ? 0.0 : list.budgetLimit;

      if (budget > 0) {
        totalBudget += budget;
        activeBudgets += 1;
      }

      double listSpent = 0;
      int completedCount = 0;
      final period = _resolveBudgetPeriod(list, now);

      for (final item in items) {
        if (!item.isCompleted) continue;
        completedCount += 1;

        final value = _safeTotalPrice(item);
        final eventDate = _eventDate(item);
        if (period.contains(eventDate)) {
          listSpent += value;
        }

        if (!eventDate.isBefore(weekStart)) {
          weekToDateSpend += value;
        }
        if (!eventDate.isBefore(monthStart)) {
          monthToDateSpend += value;
        }

        final bucketKey = _startOfWeek(eventDate);
        weeklyBuckets[bucketKey] = (weeklyBuckets[bucketKey] ?? 0) + value;

        final categoryKey = item.category.trim().isEmpty
            ? 'Other'
            : item.category.trim();
        categorySpend[categoryKey] = (categorySpend[categoryKey] ?? 0) + value;

        final frequentKey = item.productId?.isNotEmpty == true
            ? 'pid:${item.productId}'
            : 'name:${item.name.toLowerCase()}';
        final entry = frequentMap.putIfAbsent(
          frequentKey,
          () => _FrequentEntry(label: item.name, productId: item.productId),
        );
        entry.totalSpend += value;
        entry.occurrences += max(1, item.quantity);
      }

      if (budget > 0) {
        totalBudgetSpent += listSpent;
        listHealth.add(
          ListBudgetHealth(
            listId: list.id,
            listName: list.name,
            budget: budget,
            spent: listSpent,
            completedItems: completedCount,
            totalItems: items.length,
            cadence: list.budgetCadence == BudgetCadence.none && budget > 0
                ? BudgetCadence.oneTime
                : list.budgetCadence,
            periodStart: period.start,
            periodEnd: period.end,
          ),
        );
      }
    }

    final averageWeeklySpend = weeklyBuckets.isEmpty
        ? 0.0
        : weeklyBuckets.values.fold<double>(0.0, (acc, value) => acc + value) /
              weeklyBuckets.length;

    final sortedWeekly = weeklyBuckets.keys.toList()..sort();
    final weeksToExpose = 8;
    final trend = <BudgetTrendPoint>[];
    if (sortedWeekly.isEmpty) {
      final start = _startOfWeek(
        now.subtract(Duration(days: 7 * (weeksToExpose - 1))),
      );
      for (var i = 0; i < weeksToExpose; i++) {
        final weekStartDate = start.add(Duration(days: i * 7));
        trend.add(
          BudgetTrendPoint(
            periodStart: weekStartDate,
            periodEnd: weekStartDate.add(const Duration(days: 6)),
            spent: 0,
          ),
        );
      }
    } else {
      final latestWeek = sortedWeekly.last;
      final firstWeekNeeded = _startOfWeek(
        latestWeek.subtract(Duration(days: 7 * (weeksToExpose - 1))),
      );
      var cursor = firstWeekNeeded;
      for (var i = 0; i < weeksToExpose; i++) {
        final value = weeklyBuckets[cursor] ?? 0;
        trend.add(
          BudgetTrendPoint(
            periodStart: cursor,
            periodEnd: cursor.add(const Duration(days: 6)),
            spent: value,
          ),
        );
        cursor = cursor.add(const Duration(days: 7));
      }
    }

    final topCategories =
        categorySpend.entries
            .map((e) => CategorySpend(category: e.key, spent: e.value))
            .toList()
          ..sort((a, b) => b.spent.compareTo(a.spent));

    final frequentPurchases =
        frequentMap.values
            .map(
              (e) => FrequentPurchase(
                label: e.label,
                productId: e.productId,
                occurrences: e.occurrences,
                totalSpend: e.totalSpend,
              ),
            )
            .toList()
          ..sort((a, b) => b.totalSpend.compareTo(a.totalSpend));

    listHealth.sort((a, b) => b.utilization.compareTo(a.utilization));

    final overview = BudgetOverview(
      totalBudget: totalBudget,
      totalSpent: totalBudgetSpent,
      remaining: totalBudget - totalBudgetSpent,
      weekToDateSpend: weekToDateSpend,
      monthToDateSpend: monthToDateSpend,
      averageWeeklySpend: averageWeeklySpend,
      isOverBudget: totalBudget > 0 && totalBudgetSpent > totalBudget,
      activeBudgets: activeBudgets,
    );

    return BudgetAnalyticsSnapshot(
      overview: overview,
      weeklyTrend: List.unmodifiable(trend),
      topCategories: List.unmodifiable(topCategories.take(5)),
      frequentPurchases: List.unmodifiable(frequentPurchases.take(6)),
      listBudgetHealth: List.unmodifiable(listHealth),
      generatedAt: now,
    );
  }

  Future<List<ShoppingListItem>> _itemsForList(ShoppingList list) async {
    final cacheEntry = _itemCache[list.id];
    final now = DateTime.now();
    if (cacheEntry != null) {
      final isFresh = now.difference(cacheEntry.fetchedAt) < _cacheTtl;
      final unchanged = cacheEntry.listUpdatedAt == list.updatedAt;
      if (isFresh && unchanged) {
        return cacheEntry.items;
      }
    }

    final items = await ShoppingListService.getListItems(list.id);
    _itemCache[list.id] = _ItemCacheEntry(
      items: items,
      fetchedAt: now,
      listUpdatedAt: list.updatedAt,
    );
    return items;
  }

  double _safeTotalPrice(ShoppingListItem item) {
    final quantity = item.quantity <= 0 ? 1 : item.quantity;
    final price = item.estimatedPrice.isFinite ? item.estimatedPrice : 0.0;
    final safePrice = price < 0 ? 0.0 : price;
    return safePrice * quantity;
  }

  DateTime _eventDate(ShoppingListItem item) {
    return item.completedAt ?? item.updatedAt;
  }

  static DateTime _startOfWeek(DateTime value) {
    final date = DateTime(value.year, value.month, value.day);
    final weekday = date.weekday; // 1 = Monday
    return date.subtract(Duration(days: weekday - 1));
  }

  static BudgetPeriod currentPeriodForList(
    ShoppingList list,
    DateTime reference,
  ) {
    return _resolveBudgetPeriod(list, reference);
  }

  static BudgetPeriod _resolveBudgetPeriod(
    ShoppingList list,
    DateTime reference,
  ) {
    final cadence = list.budgetCadence;
    final normalizedAnchor = DateTime(
      list.budgetAnchor.year,
      list.budgetAnchor.month,
      list.budgetAnchor.day,
    );
    final normalizedReference = DateTime(
      reference.year,
      reference.month,
      reference.day,
    );
    final effectiveCadence =
        cadence == BudgetCadence.none && list.budgetLimit > 0
        ? BudgetCadence.oneTime
        : cadence;

    switch (effectiveCadence) {
      case BudgetCadence.none:
        return BudgetPeriod(
          start: normalizedAnchor,
          end: null,
          cadence: BudgetCadence.none,
        );
      case BudgetCadence.oneTime:
        return BudgetPeriod(
          start: normalizedAnchor,
          end: null,
          cadence: BudgetCadence.oneTime,
        );
      case BudgetCadence.weekly:
        final anchorWeekStart = _startOfWeek(normalizedAnchor);
        final referenceWeekStart = _startOfWeek(normalizedReference);
        final diffDays = referenceWeekStart.difference(anchorWeekStart).inDays;
        final weeks = diffDays <= 0 ? 0 : diffDays ~/ 7;
        final periodStart = anchorWeekStart.add(Duration(days: weeks * 7));
        final periodEnd = periodStart.add(const Duration(days: 7));
        return BudgetPeriod(
          start: periodStart,
          end: periodEnd,
          cadence: BudgetCadence.weekly,
        );
      case BudgetCadence.monthly:
        final anchorMonth = DateTime(
          normalizedAnchor.year,
          normalizedAnchor.month,
        );
        final referenceMonth = DateTime(
          normalizedReference.year,
          normalizedReference.month,
        );
        var monthsAhead =
            (referenceMonth.year - anchorMonth.year) * 12 +
            (referenceMonth.month - anchorMonth.month);
        if (monthsAhead < 0) {
          monthsAhead = 0;
        }
        final periodStart = DateTime(
          anchorMonth.year,
          anchorMonth.month + monthsAhead,
        );
        final periodEnd = DateTime(periodStart.year, periodStart.month + 1);
        return BudgetPeriod(
          start: periodStart,
          end: periodEnd,
          cadence: BudgetCadence.monthly,
        );
    }
  }
}

class _ItemCacheEntry {
  _ItemCacheEntry({
    required this.items,
    required this.fetchedAt,
    required this.listUpdatedAt,
  });

  final List<ShoppingListItem> items;
  final DateTime fetchedAt;
  final DateTime listUpdatedAt;
}

class _FrequentEntry {
  _FrequentEntry({required this.label, this.productId});

  final String label;
  final String? productId;
  int occurrences = 0;
  double totalSpend = 0;
}
