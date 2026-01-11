import 'package:flutter/material.dart';
import '../../values/values.dart';

import 'bar_chart.dart';

class ProductivityChart extends StatelessWidget {
  const ProductivityChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.0),
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20.0)),
        color: AppColors.primaryBackgroundColor,
      ),
      child: BarChartSample1(),
    );
  }
}
