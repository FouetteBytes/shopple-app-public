import 'package:flutter/material.dart';
import '../../values/values.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/widgets/dummy/profile_dummy.dart';

class InactiveEmployeeCard extends StatelessWidget {
  final String employeeName;
  final String employeeImage;
  final ValueNotifier<bool> notifier;
  final String employeePosition;
  final Color color;

  const InactiveEmployeeCard({
    super.key,
    required this.employeeName,
    required this.color,
    required this.employeeImage,
    required this.employeePosition,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        notifier.value = !notifier.value;
      },
      child: Container(
        width: double.infinity,
        height: 80,
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.primaryBackgroundColor,
          // border: Border.all(color: AppColors.primaryBackgroundColor, width: 4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ProfileDummy(
              dummyType: ProfileDummyType.image,
              scale: 0.85,
              color: color,
              image: employeeImage,
            ),
            AppSpaces.horizontalSpace20,
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employeeName,
                  style: GoogleFonts.lato(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.4,
                  ),
                ),
                Text(
                  employeePosition,
                  style: GoogleFonts.lato(color: AppColors.secondaryText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
