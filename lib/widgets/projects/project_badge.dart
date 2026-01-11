import 'package:flutter/material.dart';
import '../../values/values.dart';

class ColouredProjectBadge extends StatelessWidget {
  const ColouredProjectBadge({
    super.key,
    required this.color,
    required this.category,
  });

  final String color;
  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: HexColor.fromHex(color),
      ),
      child: Icon(
        Icons.bookmarks,
        color: (category == "Development"
            ? Colors.black
            : AppColors.primaryText),
      ),
    );
  }
}
