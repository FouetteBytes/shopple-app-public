import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/models/budget/budget_analytics_model.dart';
import 'package:shopple/widgets/budget/budget_format_utils.dart';

class WeeklySpendChart extends StatelessWidget {
  const WeeklySpendChart({super.key, required this.trend});

  final List<BudgetTrendPoint> trend;

  @override
  Widget build(BuildContext context) {
    final maxValue = trend.isEmpty
        ? 0.0
        : trend.map((e) => e.spent).fold<double>(0, max);
    final normalizedMax = maxValue == 0 ? 100.0 : (maxValue * 1.2);
    final maxYAxis = normalizedMax < 100 ? 100.0 : normalizedMax;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryBackgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Spending',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Track how much you completed each week',
            style: GoogleFonts.lato(
              fontSize: 13,
              color: AppColors.primaryText.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.black87,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final point = trend[group.x.toInt()];
                      return BarTooltipItem(
                        '${formatWeekRange(point.periodStart, point.periodEnd)}\n',
                        GoogleFonts.lato(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        children: [
                          TextSpan(
                            text: formatCurrency(point.spent),
                            style: GoogleFonts.lato(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (value, meta) {
                        if (value <= 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            formatPlainNumber(value),
                            style: GoogleFonts.lato(
                              fontSize: 11,
                              color: AppColors.primaryText.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= trend.length) {
                          return const SizedBox.shrink();
                        }
                        final point = trend[index];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('MMM d').format(point.periodStart),
                            style: GoogleFonts.lato(
                              fontSize: 11,
                              color: AppColors.primaryText.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: normalizedMax / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.primaryText.withValues(alpha: 0.08),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                maxY: maxYAxis,
                barGroups: List.generate(trend.length, (index) {
                  final point = trend[index];
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: point.spent,
                        color: AppColors.primaryGreen,
                        width: 16,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(6),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxYAxis,
                          color: AppColors.primaryGreen.withValues(alpha: 0.08),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
