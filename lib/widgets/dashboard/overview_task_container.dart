import 'package:flutter/material.dart';
import '../../values/values.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/widgets/dashboard/task_container_image.dart';

class OverviewTaskContainer extends StatelessWidget {
  final Color backgroundColor;
  final String imageUrl;
  final String numberOfItems;
  final String cardTitle;
  const OverviewTaskContainer({
    super.key,
    required this.imageUrl,
    required this.backgroundColor,
    required this.cardTitle,
    required this.numberOfItems,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.0),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(8),
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.primaryBackgroundColor,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                TaskContainerImage(
                  imageUrl: imageUrl,
                  backgroundColor: backgroundColor,
                ),
                AppSpaces.horizontalSpace20,
                Text(
                  cardTitle,
                  style: GoogleFonts.lato(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  numberOfItems,
                  style: GoogleFonts.lato(
                    color: backgroundColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
                AppSpaces.horizontalSpace20,
                Icon(
                  Icons.chevron_right,
                  color: AppColors.primaryText,
                  size: 30,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
