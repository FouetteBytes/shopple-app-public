import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shopple/models/shopping_lists/shopping_list_item_model.dart';
import 'package:shopple/models/shopping_lists/shopping_list_model.dart';
import 'package:shopple/services/budget/realtime_budget_service.dart';
import 'package:shopple/utils/app_logger.dart';

/// AI-driven spending insights service with anomaly detection,
/// trend analysis, and intelligent budget recommendations.
class SpendingInsightsService {
  SpendingInsightsService._();
  static final SpendingInsightsService instance = SpendingInsightsService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate spending insights for the user
  Future<SpendingInsights> generateInsights(
    String userId,
    List<ShoppingList> lists,
  ) async {
    try {
      // Collect historical spending data
      final historicalSpending = await _collectHistoricalSpending(userId, lists);
      final currentSpending = RealtimeBudgetService.instance.currentSpending;

      // Calculate insights
      final anomalies = _detectAnomalies(historicalSpending, currentSpending);
      final trends = _analyzeTrends(historicalSpending);
      final recommendations = _generateRecommendations(
        historicalSpending,
        currentSpending,
        anomalies,
        trends,
      );
      final predictions = _generatePredictions(historicalSpending, currentSpending);
      final categoryInsights = _analyzeCategorySpending(historicalSpending);

      return SpendingInsights(
        anomalies: anomalies,
        trends: trends,
        recommendations: recommendations,
        predictions: predictions,
        categoryInsights: categoryInsights,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      AppLogger.e('SpendingInsightsService: Failed to generate insights', error: e);
      return SpendingInsights.empty;
    }
  }

  /// Collect historical spending data from completed items
  Future<HistoricalSpendingData> _collectHistoricalSpending(
    String userId,
    List<ShoppingList> lists,
  ) async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final ninetyDaysAgo = now.subtract(const Duration(days: 90));

    final dailySpend = <DateTime, double>{};
    final weeklySpend = <DateTime, double>{};
    final monthlySpend = <DateTime, double>{};
    final categorySpend = <String, List<SpendingEntry>>{};
    final itemFrequency = <String, int>{};

    for (final list in lists) {
      try {
        final itemsSnapshot = await _firestore
            .collection('shopping_lists')
            .doc(list.id)
            .collection('items')
            .where('isCompleted', isEqualTo: true)
            .get();

        for (final doc in itemsSnapshot.docs) {
          final item = ShoppingListItem.fromFirestore(doc);
          final eventDate = item.completedAt ?? item.updatedAt;
          final amount = _safeItemTotal(item);

          // Only include recent history for trend analysis
          if (eventDate.isAfter(ninetyDaysAgo)) {
            // Daily aggregation
            final dayKey = DateTime(eventDate.year, eventDate.month, eventDate.day);
            dailySpend[dayKey] = (dailySpend[dayKey] ?? 0) + amount;

            // Weekly aggregation
            final weekKey = _startOfWeek(eventDate);
            weeklySpend[weekKey] = (weeklySpend[weekKey] ?? 0) + amount;

            // Monthly aggregation
            final monthKey = DateTime(eventDate.year, eventDate.month);
            monthlySpend[monthKey] = (monthlySpend[monthKey] ?? 0) + amount;

            // Category tracking
            final cat = item.category.isEmpty ? 'other' : item.category;
            categorySpend.putIfAbsent(cat, () => []).add(SpendingEntry(
              amount: amount,
              date: eventDate,
            ));

            // Item frequency
            final itemKey = item.name.toLowerCase().trim();
            itemFrequency[itemKey] = (itemFrequency[itemKey] ?? 0) + 1;
          }
        }
      } catch (e) {
        AppLogger.w('SpendingInsightsService: Error processing list ${list.id}: $e');
      }
    }

    // Calculate statistics
    final last30DaysSpending = dailySpend.entries
        .where((e) => e.key.isAfter(thirtyDaysAgo))
        .fold<double>(0, (total, e) => total + e.value);

    final daysWithSpending = dailySpend.keys.where((d) => d.isAfter(thirtyDaysAgo)).length;
    final avgDailySpend = daysWithSpending > 0
        ? last30DaysSpending / daysWithSpending
        : 0.0;

    // Calculate standard deviation for anomaly detection
    final dailyValues = dailySpend.entries
        .where((e) => e.key.isAfter(thirtyDaysAgo))
        .map((e) => e.value)
        .toList();
    final stdDev = _calculateStdDev(dailyValues);

    return HistoricalSpendingData(
      dailySpend: dailySpend,
      weeklySpend: weeklySpend,
      monthlySpend: monthlySpend,
      categorySpend: categorySpend,
      itemFrequency: itemFrequency,
      avgDailySpend: avgDailySpend,
      stdDeviation: stdDev,
      last30DaysTotal: last30DaysSpending,
    );
  }

  /// Detect spending anomalies using statistical analysis
  List<SpendingAnomaly> _detectAnomalies(
    HistoricalSpendingData historical,
    RealtimeSpendingData current,
  ) {
    final anomalies = <SpendingAnomaly>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if today's spending is anomalous (> 2 std deviations from mean)
    if (historical.avgDailySpend > 0 && historical.stdDeviation > 0) {
      final todaySpend = current.todaySpent;
      final zScore = (todaySpend - historical.avgDailySpend) / historical.stdDeviation;

      if (zScore > 2.0) {
        anomalies.add(SpendingAnomaly(
          type: AnomalyType.unusuallyHighSpending,
          severity: zScore > 3.0 ? AnomalySeverity.high : AnomalySeverity.medium,
          message: 'Today\'s spending is ${(zScore).toStringAsFixed(1)}x higher than usual',
          amount: todaySpend,
          expectedAmount: historical.avgDailySpend,
          date: today,
        ));
      }
    }

    // Check for category spending anomalies
    for (final entry in current.categorySpend.entries) {
      final categoryHistory = historical.categorySpend[entry.key];
      if (categoryHistory == null || categoryHistory.length < 3) continue;

      final categoryAvg = categoryHistory.fold<double>(0, (total, e) => total + e.amount) /
          categoryHistory.length;
      if (categoryAvg <= 0) continue;

      final deviation = (entry.value - categoryAvg) / categoryAvg;
      if (deviation > 0.5) {
        // 50% higher than average
        anomalies.add(SpendingAnomaly(
          type: AnomalyType.categorySpike,
          severity: deviation > 1.0 ? AnomalySeverity.high : AnomalySeverity.medium,
          message: '${entry.key} spending is ${(deviation * 100).toStringAsFixed(0)}% higher than average',
          amount: entry.value,
          expectedAmount: categoryAvg,
          category: entry.key,
          date: today,
        ));
      }
    }

    // Check for potential budget exhaustion
    if (current.totalBudget > 0) {
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final dayOfMonth = now.day;
      final expectedUtilization = dayOfMonth / daysInMonth;
      final actualUtilization = current.utilization;

      if (actualUtilization > expectedUtilization * 1.3) {
        anomalies.add(SpendingAnomaly(
          type: AnomalyType.fastBudgetDepletion,
          severity: actualUtilization > 0.9
              ? AnomalySeverity.high
              : AnomalySeverity.medium,
          message: 'Budget is depleting faster than expected - ${(actualUtilization * 100).toStringAsFixed(0)}% used with ${daysInMonth - dayOfMonth} days left',
          amount: current.totalSpent,
          expectedAmount: current.totalBudget * expectedUtilization,
          date: today,
        ));
      }
    }

    return anomalies;
  }

  /// Analyze spending trends over time
  List<SpendingTrend> _analyzeTrends(HistoricalSpendingData historical) {
    final trends = <SpendingTrend>[];

    // Week-over-week trend
    final sortedWeeks = historical.weeklySpend.keys.toList()..sort();
    if (sortedWeeks.length >= 2) {
      final thisWeek = historical.weeklySpend[sortedWeeks.last] ?? 0;
      final lastWeek = historical.weeklySpend[sortedWeeks[sortedWeeks.length - 2]] ?? 0;

      if (lastWeek > 0) {
        final change = (thisWeek - lastWeek) / lastWeek;
        trends.add(SpendingTrend(
          period: TrendPeriod.weekly,
          currentValue: thisWeek,
          previousValue: lastWeek,
          changePercent: change * 100,
          direction: change > 0.05
              ? TrendDirection.up
              : change < -0.05
                  ? TrendDirection.down
                  : TrendDirection.stable,
        ));
      }
    }

    // Month-over-month trend
    final sortedMonths = historical.monthlySpend.keys.toList()..sort();
    if (sortedMonths.length >= 2) {
      final thisMonth = historical.monthlySpend[sortedMonths.last] ?? 0;
      final lastMonth = historical.monthlySpend[sortedMonths[sortedMonths.length - 2]] ?? 0;

      if (lastMonth > 0) {
        final change = (thisMonth - lastMonth) / lastMonth;
        trends.add(SpendingTrend(
          period: TrendPeriod.monthly,
          currentValue: thisMonth,
          previousValue: lastMonth,
          changePercent: change * 100,
          direction: change > 0.1
              ? TrendDirection.up
              : change < -0.1
                  ? TrendDirection.down
                  : TrendDirection.stable,
        ));
      }
    }

    // Category trends - find fastest growing/shrinking categories
    for (final entry in historical.categorySpend.entries) {
      final entries = entry.value..sort((a, b) => a.date.compareTo(b.date));
      if (entries.length < 4) continue;

      final midpoint = entries.length ~/ 2;
      final firstHalf = entries.sublist(0, midpoint);
      final secondHalf = entries.sublist(midpoint);

      final firstAvg = firstHalf.fold<double>(0, (s, e) => s + e.amount) / firstHalf.length;
      final secondAvg = secondHalf.fold<double>(0, (s, e) => s + e.amount) / secondHalf.length;

      if (firstAvg > 0) {
        final change = (secondAvg - firstAvg) / firstAvg;
        if (change.abs() > 0.2) {
          // Only report significant changes
          trends.add(SpendingTrend(
            period: TrendPeriod.category,
            category: entry.key,
            currentValue: secondAvg,
            previousValue: firstAvg,
            changePercent: change * 100,
            direction: change > 0
                ? TrendDirection.up
                : TrendDirection.down,
          ));
        }
      }
    }

    return trends;
  }

  /// Generate smart budget recommendations
  List<BudgetRecommendation> _generateRecommendations(
    HistoricalSpendingData historical,
    RealtimeSpendingData current,
    List<SpendingAnomaly> anomalies,
    List<SpendingTrend> trends,
  ) {
    final recommendations = <BudgetRecommendation>[];

    // Recommendation: Set a budget if none exists
    if (current.totalBudget <= 0 && historical.avgDailySpend > 0) {
      final suggestedMonthly = historical.avgDailySpend * 30 * 1.1; // 10% buffer
      recommendations.add(BudgetRecommendation(
        type: RecommendationType.setGlobalBudget,
        priority: RecommendationPriority.high,
        title: 'Set a Monthly Budget',
        description: 'AI Analysis suggests a monthly limit of Rs ${suggestedMonthly.toStringAsFixed(0)} based on your 30-day spending patterns.',
        suggestedAmount: suggestedMonthly,
        reasoning: 'Your average daily spending is Rs ${historical.avgDailySpend.toStringAsFixed(0)}',
      ));
    }

    // Recommendation: Reduce spending in high-growth categories
    final growingCategories = trends.where(
      (t) => t.period == TrendPeriod.category && t.changePercent > 30,
    );
    for (final trend in growingCategories) {
      recommendations.add(BudgetRecommendation(
        type: RecommendationType.reduceCategory,
        priority: trend.changePercent > 50
            ? RecommendationPriority.high
            : RecommendationPriority.medium,
        title: 'Review ${trend.category ?? "Unknown"} Spending',
        description: 'We noticed a ${trend.changePercent.toStringAsFixed(0)}% spike in ${trend.category ?? "category"} expenses this week. This is higher than your usual average.',
        categoryTarget: trend.category,
        reasoning: 'This category is growing faster than your overall spending',
      ));
    }

    // Recommendation: Adjust budget if consistently over/under
    if (current.totalBudget > 0) {
      if (current.utilization > 0.95) {
        recommendations.add(BudgetRecommendation(
          type: RecommendationType.increaseBudget,
          priority: RecommendationPriority.medium,
          title: 'Consider Increasing Budget',
          description: 'You\'ve used ${(current.utilization * 100).toStringAsFixed(0)}% of your budget. Consider increasing it or reducing spending.',
          suggestedAmount: current.totalBudget * 1.2,
          reasoning: 'Consistent overspending suggests budget may be too tight',
        ));
      } else if (current.utilization < 0.5 && current.activeBudgets > 0) {
        recommendations.add(BudgetRecommendation(
          type: RecommendationType.decreaseBudget,
          priority: RecommendationPriority.low,
          title: 'Optimize Your Budget',
          description: 'You\'re only using ${(current.utilization * 100).toStringAsFixed(0)}% of your budget. Consider lowering it to better track spending.',
          suggestedAmount: current.totalSpent * 1.3,
          reasoning: 'A tighter budget helps maintain spending awareness',
        ));
      }
    }

    // Recommendation: Based on anomalies
    for (final anomaly in anomalies) {
      if (anomaly.type == AnomalyType.fastBudgetDepletion) {
        recommendations.add(BudgetRecommendation(
          type: RecommendationType.reduceSpending,
          priority: RecommendationPriority.high,
          title: 'Slow Down Spending',
          description: anomaly.message,
          reasoning: 'At current rate, you\'ll exceed your budget before month end',
        ));
        break;
      }
    }

    return recommendations;
  }

  /// Generate spending predictions
  SpendingPredictions _generatePredictions(
    HistoricalSpendingData historical,
    RealtimeSpendingData current,
  ) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dayOfMonth = now.day;
    final daysRemaining = daysInMonth - dayOfMonth;

    // Simple linear projection
    final projectedMonthEnd = dayOfMonth > 0
        ? (current.monthSpent / dayOfMonth) * daysInMonth
        : current.monthSpent;

    // Weighted projection (recent days weighted more)
    final weekDays = min(7, dayOfMonth);
    final weeklyRate = weekDays > 0 ? current.weekSpent / weekDays : 0;
    final weightedProjection = current.monthSpent +
        (weeklyRate * daysRemaining * 0.7) +
        (historical.avgDailySpend * daysRemaining * 0.3);

    // Budget status projection
    final willExceedBudget = current.totalBudget > 0 &&
        projectedMonthEnd > current.totalBudget;

    // Day to exceed budget (if applicable)
    DateTime? budgetExhaustionDate;
    if (willExceedBudget && current.avgDailySpend > 0) {
      final daysToExhaust = (current.remaining / current.avgDailySpend).ceil();
      budgetExhaustionDate = now.add(Duration(days: daysToExhaust));
    }

    // Calculate safe daily spend to stay within budget
    double safeDailySpend = 0;
    if (current.totalBudget > 0 && daysRemaining > 0) {
      safeDailySpend = current.remaining / daysRemaining;
    }

    return SpendingPredictions(
      projectedMonthEnd: projectedMonthEnd,
      weightedProjection: weightedProjection,
      willExceedBudget: willExceedBudget,
      budgetExhaustionDate: budgetExhaustionDate,
      safeDailySpend: safeDailySpend,
      confidence: _calculatePredictionConfidence(historical),
    );
  }

  /// Analyze category-level spending patterns
  List<CategoryInsight> _analyzeCategorySpending(HistoricalSpendingData historical) {
    final insights = <CategoryInsight>[];

    for (final entry in historical.categorySpend.entries) {
      final entries = entry.value;
      if (entries.isEmpty) continue;

      final total = entries.fold<double>(0, (s, e) => s + e.amount);
      final avg = total / entries.length;

      // Find typical purchase day
      final dayOfWeekCounts = <int, int>{};
      for (final e in entries) {
        dayOfWeekCounts[e.date.weekday] =
            (dayOfWeekCounts[e.date.weekday] ?? 0) + 1;
      }
      final typicalDay = dayOfWeekCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      insights.add(CategoryInsight(
        category: entry.key,
        totalSpend: total,
        averageTransaction: avg,
        transactionCount: entries.length,
        typicalDayOfWeek: typicalDay,
        percentOfTotal: 0, // Will be calculated after
      ));
    }

    // Calculate percentage of total
    final grandTotal = insights.fold<double>(0, (s, i) => s + i.totalSpend);
    return insights.map((i) => CategoryInsight(
      category: i.category,
      totalSpend: i.totalSpend,
      averageTransaction: i.averageTransaction,
      transactionCount: i.transactionCount,
      typicalDayOfWeek: i.typicalDayOfWeek,
      percentOfTotal: grandTotal > 0 ? i.totalSpend / grandTotal : 0,
    )).toList()
      ..sort((a, b) => b.totalSpend.compareTo(a.totalSpend));
  }

  double _calculatePredictionConfidence(HistoricalSpendingData historical) {
    // Higher confidence with more data and lower variance
    final dataPoints = historical.dailySpend.length;
    final dataScore = min(1.0, dataPoints / 30); // Max at 30 days of data

    final varianceScore = historical.avgDailySpend > 0
        ? 1.0 - min(1.0, historical.stdDeviation / historical.avgDailySpend)
        : 0.5;

    return (dataScore * 0.6 + varianceScore * 0.4).clamp(0.0, 1.0);
  }

  double _calculateStdDev(List<double> values) {
    if (values.isEmpty) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => pow(v - mean, 2));
    final variance = squaredDiffs.reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }

  double _safeItemTotal(ShoppingListItem item) {
    final quantity = item.quantity <= 0 ? 1 : item.quantity;
    final price = item.estimatedPrice.isFinite ? item.estimatedPrice : 0.0;
    return (price < 0 ? 0.0 : price) * quantity;
  }

  static DateTime _startOfWeek(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }
}

// ============================================================================
// Data Models
// ============================================================================

class HistoricalSpendingData {
  const HistoricalSpendingData({
    required this.dailySpend,
    required this.weeklySpend,
    required this.monthlySpend,
    required this.categorySpend,
    required this.itemFrequency,
    required this.avgDailySpend,
    required this.stdDeviation,
    required this.last30DaysTotal,
  });

  final Map<DateTime, double> dailySpend;
  final Map<DateTime, double> weeklySpend;
  final Map<DateTime, double> monthlySpend;
  final Map<String, List<SpendingEntry>> categorySpend;
  final Map<String, int> itemFrequency;
  final double avgDailySpend;
  final double stdDeviation;
  final double last30DaysTotal;
}

class SpendingEntry {
  const SpendingEntry({required this.amount, required this.date});
  final double amount;
  final DateTime date;
}

class SpendingInsights {
  const SpendingInsights({
    required this.anomalies,
    required this.trends,
    required this.recommendations,
    required this.predictions,
    required this.categoryInsights,
    required this.generatedAt,
  });

  static final SpendingInsights empty = SpendingInsights(
    anomalies: const [],
    trends: const [],
    recommendations: const [],
    predictions: SpendingPredictions.empty,
    categoryInsights: const [],
    generatedAt: DateTime.now(),
  );

  final List<SpendingAnomaly> anomalies;
  final List<SpendingTrend> trends;
  final List<BudgetRecommendation> recommendations;
  final SpendingPredictions predictions;
  final List<CategoryInsight> categoryInsights;
  final DateTime generatedAt;

  bool get hasHighPriorityItems =>
      anomalies.any((a) => a.severity == AnomalySeverity.high) ||
      recommendations.any((r) => r.priority == RecommendationPriority.high);
}

// ============================================================================
// Anomaly Types
// ============================================================================

enum AnomalyType {
  unusuallyHighSpending,
  categorySpike,
  fastBudgetDepletion,
  unusualPurchaseTime,
}

enum AnomalySeverity { low, medium, high }

class SpendingAnomaly {
  const SpendingAnomaly({
    required this.type,
    required this.severity,
    required this.message,
    required this.amount,
    required this.expectedAmount,
    required this.date,
    this.category,
  });

  final AnomalyType type;
  final AnomalySeverity severity;
  final String message;
  final double amount;
  final double expectedAmount;
  final DateTime date;
  final String? category;
}

// ============================================================================
// Trend Types
// ============================================================================

enum TrendPeriod { daily, weekly, monthly, category }
enum TrendDirection { up, down, stable }

class SpendingTrend {
  const SpendingTrend({
    required this.period,
    required this.currentValue,
    required this.previousValue,
    required this.changePercent,
    required this.direction,
    this.category,
  });

  final TrendPeriod period;
  final String? category;
  final double currentValue;
  final double previousValue;
  final double changePercent;
  final TrendDirection direction;
}

// ============================================================================
// Recommendation Types
// ============================================================================

enum RecommendationType {
  setGlobalBudget,
  setCategoryBudget,
  increaseBudget,
  decreaseBudget,
  reduceSpending,
  reduceCategory,
}

enum RecommendationPriority { low, medium, high }

class BudgetRecommendation {
  const BudgetRecommendation({
    required this.type,
    required this.priority,
    required this.title,
    required this.description,
    required this.reasoning,
    this.suggestedAmount,
    this.categoryTarget,
  });

  final RecommendationType type;
  final RecommendationPriority priority;
  final String title;
  final String description;
  final String reasoning;
  final double? suggestedAmount;
  final String? categoryTarget;
}

// ============================================================================
// Predictions
// ============================================================================

class SpendingPredictions {
  const SpendingPredictions({
    required this.projectedMonthEnd,
    required this.weightedProjection,
    required this.willExceedBudget,
    this.budgetExhaustionDate,
    required this.safeDailySpend,
    required this.confidence,
  });

  static const SpendingPredictions empty = SpendingPredictions(
    projectedMonthEnd: 0,
    weightedProjection: 0,
    willExceedBudget: false,
    safeDailySpend: 0,
    confidence: 0,
  );

  final double projectedMonthEnd;
  final double weightedProjection;
  final bool willExceedBudget;
  final DateTime? budgetExhaustionDate;
  final double safeDailySpend;
  final double confidence;
}

// ============================================================================
// Category Insights
// ============================================================================

class CategoryInsight {
  const CategoryInsight({
    required this.category,
    required this.totalSpend,
    required this.averageTransaction,
    required this.transactionCount,
    required this.typicalDayOfWeek,
    required this.percentOfTotal,
  });

  final String category;
  final double totalSpend;
  final double averageTransaction;
  final int transactionCount;
  final int typicalDayOfWeek;
  final double percentOfTotal;

  String get dayName {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[(typicalDayOfWeek - 1).clamp(0, 6)];
  }
}
