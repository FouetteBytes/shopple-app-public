import 'package:flutter/material.dart';
import '../../values/values.dart';

class GradientColorBall extends StatelessWidget {
  final int selectIndex;
  final ValueNotifier<int> valueChanger;
  final List<Color> gradientList;

  const GradientColorBall({
    super.key,
    required this.valueChanger,
    required this.selectIndex,
    required this.gradientList,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        valueChanger.value = selectIndex;
      },
      child: ValueListenableBuilder(
        valueListenable: valueChanger,
        builder: (BuildContext context, _, _) {
          // FIXED: Use MediaQuery instead of Utils.screenWidth
          final screenWidth = MediaQuery.of(context).size.width;
          var size = ((screenWidth - 46) / 5) - 5;

          // SAFETY CHECK: Ensure minimum size to prevent negative constraints
          size = size.clamp(30.0, 60.0); // Minimum 30, Maximum 60

          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
              border: (selectIndex == valueChanger.value)
                  ? Border.all(color: AppColors.primaryGreen, width: 2)
                  : Border.all(width: 0, color: AppColors.surface),
            ),
            child: Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [...gradientList],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
