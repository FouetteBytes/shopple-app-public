import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/services/budget/realtime_budget_service.dart';
import 'package:shopple/widgets/budget/budget_format_utils.dart';
import 'package:shopple/widgets/common/liquid_glass_button.dart';

/// Real-time spending tracker widget with live updates.
class RealtimeSpendingTracker extends StatelessWidget {
  const RealtimeSpendingTracker({
    super.key,
    required this.data,
    this.onSetBudgetTap,
    this.compact = false,
  });

  final RealtimeSpendingData data;
  final VoidCallback? onSetBudgetTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (compact) {
      return _buildCompactView(theme);
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getGradientStart(),
            _getGradientEnd(),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _getGradientStart().withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CustomPaint(
                painter: _BackgroundPatternPainter(
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme),
                const SizedBox(height: 20),
                _buildMainStats(theme),
                const SizedBox(height: 20),
                _buildProgressBar(theme),
                const SizedBox(height: 16),
                _buildPeriodStats(theme),
                if (data.alerts.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildAlertsBanner(theme),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactView(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: data.isOverBudget
              ? Colors.redAccent.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getStatusColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getStatusIcon(),
              color: _getStatusColor(),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today: ${formatCurrency(data.todaySpent)}',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.totalBudget > 0
                      ? '${formatCurrency(data.remaining)} remaining'
                      : 'This month: ${formatCurrency(data.monthSpent)}',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          if (data.totalBudget > 0)
            _buildMiniProgressRing(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live Spending',
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent.withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Real-time',
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        if (data.totalBudget <= 0 && onSetBudgetTap != null)
          LiquidGlassButton.icon(
            onTap: onSetBudgetTap,
            icon: Icons.add_rounded,
            iconColor: Colors.white,
            size: 36,
            iconSize: 18,
          ),
      ],
    );
  }

  Widget _buildMainStats(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Spent',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatCurrency(data.totalSpent),
                style: GoogleFonts.lato(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        if (data.totalBudget > 0)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'of ${formatCurrency(data.totalBudget)}',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${formatCurrency(data.remaining)} left',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildProgressBar(ThemeData theme) {
    if (data.totalBudget <= 0) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: data.utilization.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              data.isOverBudget
                  ? Colors.redAccent
                  : Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(data.utilization * 100).toStringAsFixed(0)}% used',
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            if (data.projectedMonthSpend > 0)
              Text(
                'Projected: ${formatCurrency(data.projectedMonthSpend)}',
                style: GoogleFonts.lato(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodStats(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildPeriodStat(
            'Today',
            data.todaySpent,
            Icons.today_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPeriodStat(
            'This Week',
            data.weekSpent,
            Icons.date_range_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPeriodStat(
            'This Month',
            data.monthSpent,
            Icons.calendar_month_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodStat(String label, double value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 18),
          const SizedBox(height: 6),
          Text(
            formatCurrency(value),
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsBanner(ThemeData theme) {
    final highestAlert = data.alerts.reduce(
      (a, b) => a.type.index > b.type.index ? a : b,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getAlertIcon(highestAlert.type),
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              highestAlert.message,
              style: GoogleFonts.lato(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _getAlertColor(highestAlert.type),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${data.alerts.length} alert${data.alerts.length > 1 ? 's' : ''}',
              style: GoogleFonts.lato(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniProgressRing(ThemeData theme) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: data.utilization.clamp(0.0, 1.0),
            strokeWidth: 4,
            backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
          ),
          Text(
            '${(data.utilization * 100).toStringAsFixed(0)}%',
            style: GoogleFonts.lato(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Color _getGradientStart() {
    if (data.isOverBudget) return Colors.red[600]!;
    if (data.utilization > 0.9) return Colors.orange[600]!;
    if (data.utilization > 0.75) return Colors.amber[600]!;
    return AppColors.primaryGreen;
  }

  Color _getGradientEnd() {
    if (data.isOverBudget) return Colors.red[800]!;
    if (data.utilization > 0.9) return Colors.orange[800]!;
    if (data.utilization > 0.75) return Colors.amber[800]!;
    return AppColors.primaryGreen.withValues(alpha: 0.8);
  }

  Color _getStatusColor() {
    if (data.isOverBudget) return Colors.redAccent;
    if (data.utilization > 0.9) return Colors.orange;
    if (data.utilization > 0.75) return Colors.amber;
    return AppColors.primaryGreen;
  }

  IconData _getStatusIcon() {
    if (data.isOverBudget) return Icons.warning_rounded;
    if (data.utilization > 0.9) return Icons.trending_up_rounded;
    if (data.utilization > 0.75) return Icons.show_chart_rounded;
    return Icons.check_circle_outline_rounded;
  }

  IconData _getAlertIcon(BudgetAlertType type) {
    switch (type) {
      case BudgetAlertType.warning:
        return Icons.info_outline_rounded;
      case BudgetAlertType.nearLimit:
        return Icons.warning_amber_rounded;
      case BudgetAlertType.exceeded:
        return Icons.error_outline_rounded;
    }
  }

  Color _getAlertColor(BudgetAlertType type) {
    switch (type) {
      case BudgetAlertType.warning:
        return Colors.amber;
      case BudgetAlertType.nearLimit:
        return Colors.orange;
      case BudgetAlertType.exceeded:
        return Colors.redAccent;
    }
  }
}

/// Custom painter for background pattern
class _BackgroundPatternPainter extends CustomPainter {
  _BackgroundPatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const spacing = 30.0;
    for (var i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
