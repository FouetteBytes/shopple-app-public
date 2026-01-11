import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/services/budget/spending_insights_service.dart';
import 'package:shopple/widgets/budget/budget_format_utils.dart';

/// Card displaying AI-driven spending insights and recommendations.
class SpendingInsightsCard extends StatelessWidget {
  const SpendingInsightsCard({
    super.key,
    required this.insights,
    this.onRecommendationTap,
  });

  final SpendingInsights insights;
  final void Function(BudgetRecommendation)? onRecommendationTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasContent = insights.anomalies.isNotEmpty ||
        insights.recommendations.isNotEmpty ||
        insights.predictions.willExceedBudget;

    if (!hasContent) {
      return _buildEmptyState(theme);
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          if (insights.anomalies.isNotEmpty) ...[
            const Divider(height: 1),
            _buildAnomaliesSection(theme),
          ],
          if (insights.predictions.willExceedBudget) ...[
            const Divider(height: 1),
            _buildPredictionWarning(theme),
          ],
          if (insights.recommendations.isNotEmpty) ...[
            const Divider(height: 1),
            _buildRecommendationsSection(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.insights_rounded,
            size: 40,
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No insights yet',
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Keep tracking your spending to see smart insights',
            style: GoogleFonts.lato(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Insights',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  'AI-powered spending analysis',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          if (insights.hasHighPriorityItems)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.priority_high_rounded,
                    color: Colors.redAccent,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Action needed',
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnomaliesSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending Alerts',
            style: GoogleFonts.lato(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          ...insights.anomalies.map((anomaly) => _buildAnomalyItem(theme, anomaly)),
        ],
      ),
    );
  }

  Widget _buildAnomalyItem(ThemeData theme, SpendingAnomaly anomaly) {
    final color = _getSeverityColor(anomaly.severity);
    final icon = _getAnomalyIcon(anomaly.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  anomaly.message,
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Expected: ${formatCurrency(anomaly.expectedAmount)} • Actual: ${formatCurrency(anomaly.amount)}',
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionWarning(ThemeData theme) {
    final predictions = insights.predictions;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Budget Projection Warning',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[800],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'At current rate, you\'ll spend ${formatCurrency(predictions.projectedMonthEnd)} by month end',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: Colors.orange[700],
                  ),
                ),
                if (predictions.safeDailySpend > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 14,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Safe daily spend: ${formatCurrency(predictions.safeDailySpend)}',
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(ThemeData theme) {
    final highPriority = insights.recommendations
        .where((r) => r.priority == RecommendationPriority.high)
        .toList();
    final otherRecs = insights.recommendations
        .where((r) => r.priority != RecommendationPriority.high)
        .take(2)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommendations',
            style: GoogleFonts.lato(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          ...highPriority.map((rec) => _buildRecommendationItem(theme, rec, isHighPriority: true)),
          ...otherRecs.map((rec) => _buildRecommendationItem(theme, rec)),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(
    ThemeData theme,
    BudgetRecommendation recommendation, {
    bool isHighPriority = false,
  }) {
    return GestureDetector(
      onTap: onRecommendationTap != null
          ? () => onRecommendationTap!(recommendation)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isHighPriority
              ? AppColors.primaryGreen.withValues(alpha: 0.08)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHighPriority
                ? AppColors.primaryGreen.withValues(alpha: 0.3)
                : theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _getRecommendationColor(recommendation.type)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getRecommendationIcon(recommendation.type),
                color: _getRecommendationColor(recommendation.type),
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recommendation.title,
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    recommendation.description,
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (onRecommendationTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Colors.grey,
              ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(AnomalySeverity severity) {
    switch (severity) {
      case AnomalySeverity.low:
        return Colors.blue;
      case AnomalySeverity.medium:
        return Colors.orange;
      case AnomalySeverity.high:
        return Colors.redAccent;
    }
  }

  IconData _getAnomalyIcon(AnomalyType type) {
    switch (type) {
      case AnomalyType.unusuallyHighSpending:
        return Icons.trending_up_rounded;
      case AnomalyType.categorySpike:
        return Icons.category_rounded;
      case AnomalyType.fastBudgetDepletion:
        return Icons.speed_rounded;
      case AnomalyType.unusualPurchaseTime:
        return Icons.schedule_rounded;
    }
  }

  Color _getRecommendationColor(RecommendationType type) {
    switch (type) {
      case RecommendationType.setGlobalBudget:
      case RecommendationType.setCategoryBudget:
        return AppColors.primaryGreen;
      case RecommendationType.increaseBudget:
        return Colors.blue;
      case RecommendationType.decreaseBudget:
        return Colors.teal;
      case RecommendationType.reduceSpending:
      case RecommendationType.reduceCategory:
        return Colors.orange;
    }
  }

  IconData _getRecommendationIcon(RecommendationType type) {
    switch (type) {
      case RecommendationType.setGlobalBudget:
        return Icons.account_balance_wallet_rounded;
      case RecommendationType.setCategoryBudget:
        return Icons.category_rounded;
      case RecommendationType.increaseBudget:
        return Icons.add_chart_rounded;
      case RecommendationType.decreaseBudget:
        return Icons.remove_circle_outline_rounded;
      case RecommendationType.reduceSpending:
        return Icons.savings_rounded;
      case RecommendationType.reduceCategory:
        return Icons.pie_chart_rounded;
    }
  }
}
