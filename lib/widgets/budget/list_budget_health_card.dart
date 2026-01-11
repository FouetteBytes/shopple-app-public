import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/models/budget/budget_analytics_model.dart';
import 'package:shopple/models/budget/budget_period.dart';
import 'package:shopple/models/budget/budget_cadence.dart';
import 'package:shopple/widgets/budget/budget_format_utils.dart';

class ListBudgetHealthCard extends StatelessWidget {
  const ListBudgetHealthCard({super.key, required this.health});

  final List<ListBudgetHealth> health;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryBackgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget Health by List',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            health.isEmpty
                ? 'Set budgets on your lists to monitor performance.'
                : 'How each list is tracking against its budget',
            style: GoogleFonts.lato(
              fontSize: 13,
              color: AppColors.primaryText.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          if (health.isEmpty)
            _EmptyState()
          else
            Column(
              children: health.map((entry) {
                final percent = entry.budget <= 0
                    ? 0.0
                    : (entry.spent / entry.budget).clamp(0.0, 1.0);
                final periodLabel = entry.cadence == BudgetCadence.none
                    ? 'Budget not configured'
                    : BudgetPeriod(
                        start: entry.periodStart,
                        end: entry.periodEnd,
                        cadence: entry.cadence,
                      ).formattedLabel();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.listName,
                              style: GoogleFonts.lato(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ),
                          Text(
                            '${formatCurrency(entry.spent)} / ${formatCurrency(entry.budget)}',
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              color: AppColors.primaryText.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.cadence == BudgetCadence.none
                            ? 'Set a cadence to track spending windows.'
                            : '${entry.cadenceLabel} • $periodLabel',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: AppColors.primaryText.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(8),
                        ),
                        child: LinearProgressIndicator(
                          value: percent,
                          minHeight: 10,
                          backgroundColor: AppColors.primaryText.withValues(
                            alpha: 0.08,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            entry.isOverBudget
                                ? Colors.redAccent
                                : AppColors.primaryGreen,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entry.isOverBudget
                            ? 'Over by ${formatCurrency(entry.spent - entry.budget)}'
                            : 'Remaining ${formatCurrency(entry.remaining)} • ${entry.completedItems}/${entry.totalItems} items complete',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: AppColors.primaryText.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(
          color: AppColors.primaryText.withValues(alpha: 0.08),
        ),
      ),
      child: Center(
        child: Text(
          'Add a budget limit when creating a list to see it here.',
          style: GoogleFonts.lato(
            color: AppColors.primaryText.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}
