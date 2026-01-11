import 'package:flutter/material.dart';
import '../../values/values.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/screens/task/task_due_date.dart';

class SheetGoToCalendarWidget extends StatelessWidget {
  final String label;
  final String value;
  final Color cardBackgroundColor;
  final Color textAccentColor;
  const SheetGoToCalendarWidget({
    super.key,
    required this.label,
    required this.value,
    required this.cardBackgroundColor,
    required this.textAccentColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.to(() => TaskDueDate());
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircularCalendarCard(color: cardBackgroundColor),
          AppSpaces.horizontalSpace10,
          Expanded(
            child: CircularCardLabel(
              label: label,
              value: value,
              color: textAccentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class CircularCalendarCard extends StatelessWidget {
  final Color color;
  const CircularCalendarCard({required this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40 * 1.5,
      height: 40 * 1.5,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(Icons.calendar_today, color: AppColors.primaryText),
    );
  }
}

class CircularCardLabel extends StatelessWidget {
  final String? label;
  final String? value;
  final Color? color;
  const CircularCardLabel({super.key, this.label, this.color, this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSpaces.verticalSpace10,
        if (label != null)
          Text(
            label!,
            style: GoogleFonts.lato(
              fontSize: 16,
              color: HexColor.fromHex("626777"),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        if (value != null)
          Text(
            value!,
            style: GoogleFonts.lato(fontSize: 16, color: color),
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}
