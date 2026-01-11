import 'package:flutter/material.dart';
import '../../values/values.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:shopple/widgets/dummy/green_done_icon.dart';

import 'dummy/profile_dummy.dart';

class ActiveEmployeeCard extends StatelessWidget {
  final String employeeName;
  final String employeeImage;
  final Color color;
  final String employeePosition;
  final ValueNotifier<bool> notifier;

  const ActiveEmployeeCard({
    super.key,
    required this.employeeName,
    required this.employeeImage,
    required this.employeePosition,
    required this.notifier,
    required this.color,
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.pink, AppColors.lightMauveBackgroundColor],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: EdgeInsets.all(2.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.surface,
            ),
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ProfileDummy(
                          dummyType: ProfileDummyType.image,
                          scale: 0.85,
                          color: color,
                          image: employeeImage,
                        ),
                        AppSpaces.horizontalSpace20,
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employeeName,
                              style: GoogleFonts.lato(
                                color: AppColors.primaryText,
                                fontWeight: FontWeight.w600,
                                fontSize: 14.2,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              employeePosition,
                              style: GoogleFonts.lato(
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: GreenDoneIcon(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
