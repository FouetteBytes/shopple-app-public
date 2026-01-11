import 'package:flutter/material.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/controllers/budget_analytics_controller.dart';
import 'package:shopple/models/budget/budget_analytics_model.dart';
import 'package:shopple/services/budget/spending_insights_service.dart';
import 'package:shopple/widgets/budget/budget_overview_card.dart';
import 'package:shopple/widgets/budget/budget_settings_sheet.dart';
import 'package:shopple/widgets/budget/category_spend_pills.dart';
import 'package:shopple/widgets/budget/frequent_purchases_card.dart';
import 'package:shopple/widgets/budget/list_budget_health_card.dart';
import 'package:shopple/widgets/budget/realtime_spending_tracker.dart';
import 'package:shopple/widgets/budget/spending_insights_card.dart';
import 'package:shopple/widgets/budget/weekly_spend_chart.dart';

class DashboardBudget extends StatefulWidget {
  const DashboardBudget({super.key, this.controller});

  final BudgetAnalyticsController? controller;

  @override
  State<DashboardBudget> createState() => _DashboardBudgetState();
}

class _DashboardBudgetState extends State<DashboardBudget> {
  late final BudgetAnalyticsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? BudgetAnalyticsController();
    // ignore: discarded_futures
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;
        switch (state.status) {
          case BudgetAnalyticsStatus.loading:
          case BudgetAnalyticsStatus.idle:
            return const _LoadingState();
          case BudgetAnalyticsStatus.error:
            return _ErrorState(
              message: state.errorMessage ?? 'Could not load budget analytics.',
              onRetry: _controller.refresh,
            );
          case BudgetAnalyticsStatus.ready:
            final snapshot = state.snapshot ?? BudgetAnalyticsSnapshot.empty;
            return _BudgetAnalyticsContent(
              snapshot: snapshot,
              controller: _controller,
            );
        }
      },
    );
  }
}

class _BudgetAnalyticsContent extends StatelessWidget {
  const _BudgetAnalyticsContent({
    required this.snapshot,
    required this.controller,
  });

  final BudgetAnalyticsSnapshot snapshot;
  final BudgetAnalyticsController controller;

  @override
  Widget build(BuildContext context) {
    final realtimeData = controller.realtimeData;
    final insights = controller.insights;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Real-time spending tracker (when available)
        if (realtimeData != null) ...[
          RealtimeSpendingTracker(
            data: realtimeData,
            onSetBudgetTap: () => _showBudgetSettings(context),
          ),
          AppSpaces.verticalSpace20,
        ] else ...[
          BudgetOverviewCard(
            overview: snapshot.overview,
            weeklyTrend: snapshot.weeklyTrend,
          ),
          AppSpaces.verticalSpace20,
        ],

        // AI-powered spending insights
        if (insights != null) ...[
          SpendingInsightsCard(
            insights: insights,
            onRecommendationTap: (rec) => _handleRecommendation(context, rec),
          ),
          AppSpaces.verticalSpace20,
        ],

        // Weekly spend chart
        WeeklySpendChart(trend: snapshot.weeklyTrend),
        AppSpaces.verticalSpace20,

        // Category breakdown
        if (snapshot.topCategories.isNotEmpty) ...[
          CategorySpendPills(categories: snapshot.topCategories),
          AppSpaces.verticalSpace20,
        ],

        // Frequent purchases
        FrequentPurchasesCard(purchases: snapshot.frequentPurchases),
        AppSpaces.verticalSpace20,

        // List budget health
        ListBudgetHealthCard(health: snapshot.listBudgetHealth),
      ],
    );
  }

  void _showBudgetSettings(BuildContext context) {
    BudgetSettingsSheet.show(context);
  }

  void _handleRecommendation(BuildContext context, BudgetRecommendation rec) {
    // Handle recommendation actions
    if (rec.type == RecommendationType.setGlobalBudget ||
        rec.type == RecommendationType.increaseBudget ||
        rec.type == RecommendationType.decreaseBudget) {
      BudgetSettingsSheet.show(
        context,
        suggestedAmount: rec.suggestedAmount,
      );
    }
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading budget analytics...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.primaryBackgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
