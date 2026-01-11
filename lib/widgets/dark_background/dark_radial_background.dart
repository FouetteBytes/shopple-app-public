import 'package:flutter/material.dart';
import '../../values/values.dart';

// ignore: must_be_immutable
class DarkRadialBackground extends StatelessWidget {
  final String position;
  final Color color;
  var list = List.generate(3, (index) => AppColors.surface);
  DarkRadialBackground({
    super.key,
    required this.color,
    required this.position,
  });
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [...list, color],
            center: (position == "bottomRight")
                ? Alignment(1.0, 1.0)
                : Alignment(-1.0, -1.0),
          ),
        ),
      ),
    );
  }
}
