import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shopple/models/budget/budget_cadence.dart';

/// Types of budget goals users can set
enum BudgetGoalType {
  /// Overall spending budget across all lists
  global,

  /// Budget for a specific shopping list
  list,

  /// Budget for a spending category (e.g., groceries, household)
  category,

  /// Budget for a specific item or product
  item,
}

/// A user-defined budget goal with tracking capability
class BudgetGoal {
  const BudgetGoal({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.cadence,
    required this.createdAt,
    this.targetId,
    this.targetName,
    this.alertThreshold = 0.8,
    this.isActive = true,
    this.notes,
    this.anchorDate,
  });

  /// Unique ID for this budget goal
  final String id;

  /// User who owns this budget
  final String userId;

  /// Type of budget goal
  final BudgetGoalType type;

  /// Target ID (listId, category name, or productId depending on type)
  final String? targetId;

  /// Human-readable target name for display
  final String? targetName;

  /// Budget amount
  final double amount;

  /// Budget cadence (weekly, monthly, etc.)
  final BudgetCadence cadence;

  /// When to trigger alerts (0.8 = 80% of budget)
  final double alertThreshold;

  /// Whether this budget is currently active
  final bool isActive;

  /// Optional user notes about this budget
  final String? notes;

  /// Anchor date for cadence calculation
  final DateTime? anchorDate;

  /// When this goal was created
  final DateTime createdAt;

  factory BudgetGoal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BudgetGoal.fromMap(doc.id, data);
  }

  factory BudgetGoal.fromMap(String id, Map<String, dynamic> data) {
    DateTime toDate(dynamic v, {DateTime? fallback}) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return fallback ?? DateTime.now();
    }

    return BudgetGoal(
      id: id,
      userId: data['userId'] ?? '',
      type: BudgetGoalType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => BudgetGoalType.global,
      ),
      targetId: data['targetId'],
      targetName: data['targetName'],
      amount: (data['amount'] ?? 0.0).toDouble(),
      cadence: BudgetCadenceStorage.fromStorage(data['cadence']?.toString()),
      alertThreshold: (data['alertThreshold'] ?? 0.8).toDouble(),
      isActive: data['isActive'] ?? true,
      notes: data['notes'],
      anchorDate: data['anchorDate'] != null
          ? toDate(data['anchorDate'])
          : null,
      createdAt: toDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'targetId': targetId,
      'targetName': targetName,
      'amount': amount,
      'cadence': cadence.storageValue,
      'alertThreshold': alertThreshold,
      'isActive': isActive,
      'notes': notes,
      'anchorDate': anchorDate != null
          ? Timestamp.fromDate(anchorDate!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  BudgetGoal copyWith({
    String? id,
    String? userId,
    BudgetGoalType? type,
    String? targetId,
    String? targetName,
    double? amount,
    BudgetCadence? cadence,
    double? alertThreshold,
    bool? isActive,
    String? notes,
    DateTime? anchorDate,
    DateTime? createdAt,
  }) {
    return BudgetGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      targetName: targetName ?? this.targetName,
      amount: amount ?? this.amount,
      cadence: cadence ?? this.cadence,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      anchorDate: anchorDate ?? this.anchorDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get the display label for this budget goal
  String get displayLabel {
    switch (type) {
      case BudgetGoalType.global:
        return 'Overall Budget';
      case BudgetGoalType.list:
        return targetName ?? 'Shopping List';
      case BudgetGoalType.category:
        return targetName ?? targetId ?? 'Category';
      case BudgetGoalType.item:
        return targetName ?? 'Item';
    }
  }

  /// Get the cadence display label
  String get cadenceLabel {
    switch (cadence) {
      case BudgetCadence.none:
        return 'No limit';
      case BudgetCadence.oneTime:
        return 'One-time';
      case BudgetCadence.weekly:
        return 'Weekly';
      case BudgetCadence.monthly:
        return 'Monthly';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BudgetGoal && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Progress tracking for a budget goal
class BudgetGoalProgress {
  const BudgetGoalProgress({
    required this.goal,
    required this.spent,
    required this.periodStart,
    required this.periodEnd,
  });

  final BudgetGoal goal;
  final double spent;
  final DateTime periodStart;
  final DateTime? periodEnd;

  double get remaining => (goal.amount - spent).clamp(0, double.infinity);
  double get utilization =>
      goal.amount > 0 ? (spent / goal.amount).clamp(0.0, 2.0) : 0.0;
  bool get isOverBudget => goal.amount > 0 && spent > goal.amount;
  bool get isNearAlert => utilization >= goal.alertThreshold;

  /// Days remaining in the current period
  int? get daysRemaining {
    if (periodEnd == null) return null;
    final now = DateTime.now();
    if (now.isAfter(periodEnd!)) return 0;
    return periodEnd!.difference(now).inDays;
  }

  /// Projected spending by end of period based on current rate
  double get projectedSpend {
    if (periodEnd == null) return spent;
    final now = DateTime.now();
    final elapsed = now.difference(periodStart).inDays;
    if (elapsed <= 0) return spent;

    final totalDays = periodEnd!.difference(periodStart).inDays;
    if (totalDays <= 0) return spent;

    final dailyRate = spent / elapsed;
    return dailyRate * totalDays;
  }

  /// Suggested daily budget to stay within goal
  double get suggestedDailyBudget {
    final days = daysRemaining;
    if (days == null || days <= 0) return 0;
    return remaining / days;
  }
}

/// Summary of all active budget goals for a user
class BudgetGoalsSummary {
  const BudgetGoalsSummary({
    required this.goals,
    required this.totalBudgeted,
    required this.totalSpent,
    required this.goalsOnTrack,
    required this.goalsNearLimit,
    required this.goalsExceeded,
  });

  static const BudgetGoalsSummary empty = BudgetGoalsSummary(
    goals: [],
    totalBudgeted: 0,
    totalSpent: 0,
    goalsOnTrack: 0,
    goalsNearLimit: 0,
    goalsExceeded: 0,
  );

  final List<BudgetGoalProgress> goals;
  final double totalBudgeted;
  final double totalSpent;
  final int goalsOnTrack;
  final int goalsNearLimit;
  final int goalsExceeded;

  double get remaining => (totalBudgeted - totalSpent).clamp(0, double.infinity);
  double get utilization =>
      totalBudgeted > 0 ? (totalSpent / totalBudgeted).clamp(0.0, 2.0) : 0.0;
  bool get isOverBudget => totalBudgeted > 0 && totalSpent > totalBudgeted;

  int get totalGoals => goals.length;
  int get activeGoals =>
      goals.where((g) => g.goal.isActive).length;
}
