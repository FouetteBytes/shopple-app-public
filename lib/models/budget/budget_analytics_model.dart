import 'package:equatable/equatable.dart';
import 'package:shopple/models/budget/budget_cadence.dart';

class BudgetAnalyticsSnapshot extends Equatable {
  final BudgetOverview overview;
  final List<BudgetTrendPoint> weeklyTrend;
  final List<CategorySpend> topCategories;
  final List<FrequentPurchase> frequentPurchases;
  final List<ListBudgetHealth> listBudgetHealth;
  final DateTime generatedAt;

  const BudgetAnalyticsSnapshot({
    required this.overview,
    required this.weeklyTrend,
    required this.topCategories,
    required this.frequentPurchases,
    required this.listBudgetHealth,
    required this.generatedAt,
  });

  @override
  List<Object?> get props => [
    overview,
    weeklyTrend,
    topCategories,
    frequentPurchases,
    listBudgetHealth,
    generatedAt,
  ];

  static final empty = BudgetAnalyticsSnapshot(
    overview: BudgetOverview.empty,
    weeklyTrend: const [],
    topCategories: const [],
    frequentPurchases: const [],
    listBudgetHealth: const [],
    generatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );
}

class BudgetOverview extends Equatable {
  final double totalBudget;
  final double totalSpent;
  final double remaining;
  final double weekToDateSpend;
  final double monthToDateSpend;
  final double averageWeeklySpend;
  final bool isOverBudget;
  final int activeBudgets;

  const BudgetOverview({
    required this.totalBudget,
    required this.totalSpent,
    required this.remaining,
    required this.weekToDateSpend,
    required this.monthToDateSpend,
    required this.averageWeeklySpend,
    required this.isOverBudget,
    required this.activeBudgets,
  });

  static const empty = BudgetOverview(
    totalBudget: 0,
    totalSpent: 0,
    remaining: 0,
    weekToDateSpend: 0,
    monthToDateSpend: 0,
    averageWeeklySpend: 0,
    isOverBudget: false,
    activeBudgets: 0,
  );

  double get utilization =>
      totalBudget <= 0 ? 0 : (totalSpent / totalBudget).clamp(0, 1.5);

  @override
  List<Object?> get props => [
    totalBudget,
    totalSpent,
    remaining,
    weekToDateSpend,
    monthToDateSpend,
    averageWeeklySpend,
    isOverBudget,
    activeBudgets,
  ];
}

class BudgetTrendPoint extends Equatable {
  final DateTime periodStart;
  final DateTime periodEnd;
  final double spent;

  const BudgetTrendPoint({
    required this.periodStart,
    required this.periodEnd,
    required this.spent,
  });

  @override
  List<Object?> get props => [periodStart, periodEnd, spent];
}

class CategorySpend extends Equatable {
  final String category;
  final double spent;

  const CategorySpend({required this.category, required this.spent});

  @override
  List<Object?> get props => [category, spent];
}

class FrequentPurchase extends Equatable {
  final String label;
  final String? productId;
  final int occurrences;
  final double totalSpend;

  const FrequentPurchase({
    required this.label,
    this.productId,
    required this.occurrences,
    required this.totalSpend,
  });

  double get averageSpend => occurrences == 0 ? 0 : totalSpend / occurrences;

  @override
  List<Object?> get props => [label, productId, occurrences, totalSpend];
}

class ListBudgetHealth extends Equatable {
  final String listId;
  final String listName;
  final double budget;
  final double spent;
  final int completedItems;
  final int totalItems;
  final BudgetCadence cadence;
  final DateTime periodStart;
  final DateTime? periodEnd;

  const ListBudgetHealth({
    required this.listId,
    required this.listName,
    required this.budget,
    required this.spent,
    required this.completedItems,
    required this.totalItems,
    required this.cadence,
    required this.periodStart,
    this.periodEnd,
  });

  double get utilization => budget <= 0 ? 0 : spent / budget;
  double get remaining => budget - spent;
  bool get isOverBudget => budget > 0 && spent > budget;
  String get cadenceLabel => cadence.displayLabel;

  @override
  List<Object?> get props => [
    listId,
    listName,
    budget,
    spent,
    completedItems,
    totalItems,
    cadence,
    periodStart,
    periodEnd,
  ];
}
