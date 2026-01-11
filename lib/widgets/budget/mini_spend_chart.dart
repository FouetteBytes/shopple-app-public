import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shopple/models/budget/budget_analytics_model.dart';

class MiniSpendChart extends StatelessWidget {
  const MiniSpendChart({super.key, required this.trend, this.color = Colors.white});

  final List<BudgetTrendPoint> trend;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) return const SizedBox.shrink();

    final maxValue = trend.map((e) => e.spent).fold<double>(0, max);
    final maxY = maxValue == 0 ? 100.0 : maxValue * 1.2;

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (trend.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: trend
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.spent))
                .toList(),
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.15),
            ),
          ),
        ],
        lineTouchData: const LineTouchData(enabled: false),
      ),
    );
  }
}
