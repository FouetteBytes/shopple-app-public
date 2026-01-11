import 'package:flutter/material.dart';
import '../../values/values.dart';

class DashboardAddButton extends StatelessWidget {
  final VoidCallback? iconTapped;
  const DashboardAddButton({super.key, this.iconTapped});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: iconTapped,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.primaryAccentColor,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.add, color: AppColors.primaryText),
      ),
    );
  }
}
