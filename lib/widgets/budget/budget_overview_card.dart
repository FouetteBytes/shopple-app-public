import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/models/budget/budget_analytics_model.dart';
import 'package:shopple/widgets/budget/budget_format_utils.dart';
import 'package:shopple/widgets/common/liquid_glass.dart';
import 'package:shopple/bottom_sheets/bottom_sheets.dart';
import 'package:shopple/widgets/budget/mini_spend_chart.dart';
import 'package:shopple/widgets/common/liquid_glass_button.dart';

class BudgetOverviewCard extends StatelessWidget {
  const BudgetOverviewCard({
    super.key,
    required this.overview,
    this.weeklyTrend,
  });

  final BudgetOverview overview;
  final List<BudgetTrendPoint>? weeklyTrend;

  @override
  Widget build(BuildContext context) {
    final percent = overview.totalBudget <= 0
        ? 0.0
        : (overview.totalSpent / overview.totalBudget).clamp(0.0, 1.0);

    // Modern blue gradient similar to the screenshot
    final gradientColors = [
      const Color(0xFF2563EB), // Bright Blue
      const Color(0xFF1D4ED8), // Deep Blue
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showBudgetDetails(context),
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Budget Overview',
                      style: GoogleFonts.lato(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _BudgetSummaryRow(overview: overview),
                const SizedBox(height: 24),
                // Animated Progress Bar
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: percent),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 10,
                            backgroundColor: Colors.black.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              overview.isOverBudget
                                  ? const Color(0xFFFF8A80) // Soft Red
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'Week to date',
                        value: formatCurrency(overview.weekToDateSpend),
                        compact: true,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _MetricTile(
                        label: 'Month to date',
                        value: formatCurrency(overview.monthToDateSpend),
                        compact: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          overview.totalBudget <= 0
                              ? 'Create a budget to start tracking.'
                              : overview.isOverBudget
                                  ? 'Over by ${formatCurrency(overview.totalSpent - overview.totalBudget)}'
                                  : 'Remaining: ${formatCurrency(overview.remaining)}',
                          style: GoogleFonts.lato(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (overview.activeBudgets > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Tracking ${overview.activeBudgets} active budgets. Avg weekly: ${formatCurrency(overview.averageWeeklySpend)}',
                    style: GoogleFonts.lato(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBudgetDetails(BuildContext context) {
    showAppBottomSheet(
      LiquidGlass(
        enableBlur: true,
        blurSigmaX: 12,
        blurSigmaY: 20,
        borderRadius: 24,
        padding: const EdgeInsets.all(24),
        gradientColors: [
          const Color(0xFF1F2937).withValues(alpha: 0.85),
          const Color(0xFF111827).withValues(alpha: 0.95),
        ],
        borderColor: Colors.white.withValues(alpha: 0.1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Budget Details',
                  style: GoogleFonts.lato(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (weeklyTrend != null && weeklyTrend!.isNotEmpty) ...[
              Text(
                'Weekly Trend',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: MiniSpendChart(
                  trend: weeklyTrend!,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 24),
            ],
            _DetailRow(
              label: 'Total Budget',
              value: formatCurrency(overview.totalBudget),
              icon: Icons.account_balance_wallet_outlined,
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 16),
            _DetailRow(
              label: 'Total Spent',
              value: formatCurrency(overview.totalSpent),
              icon: Icons.shopping_bag_outlined,
              color: Colors.orangeAccent,
            ),
            const SizedBox(height: 16),
            _DetailRow(
              label: 'Remaining',
              value: formatCurrency(overview.remaining),
              icon: Icons.savings_outlined,
              color: Colors.greenAccent,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: LiquidGlassButton.primary(
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to full budget management screen
                },
                gradientColors: [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                padding: const EdgeInsets.symmetric(vertical: 16),
                borderRadius: 16,
                text: 'Manage Budgets',
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _BudgetSummaryRow extends StatelessWidget {
  const _BudgetSummaryRow({required this.overview});

  final BudgetOverview overview;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _MetricTile(
            label: 'Total spend',
            value: formatCurrency(overview.totalSpent),
            emphasize: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MetricTile(
            label: 'Total budget',
            value: overview.totalBudget <= 0
                ? 'Not set'
                : formatCurrency(overview.totalBudget),
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.compact = false,
  });

  final String label;
  final String value;
  final bool emphasize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: compact ? 2 : 6),
        Text(
          value,
          style: GoogleFonts.lato(
            fontSize: emphasize ? 28 : (compact ? 16 : 20),
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.lato(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
