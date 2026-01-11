import 'package:flutter/material.dart';
import '../../values/values.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/widgets/dashboard/in_bottomsheet_subtitle.dart';

class LabelledSelectableContainer extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? containerColor;
  final Color? valueColor;
  const LabelledSelectableContainer({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
    this.containerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InBottomSheetSubtitle(title: label),
        AppSpaces.verticalSpace10,
        SelectableContainer(
          value: value,
          icon: icon,
          containerColor: containerColor,
          valueColor: valueColor,
        ),
      ],
    );
  }
}

class SelectableContainer extends StatelessWidget {
  const SelectableContainer({
    super.key,
    required this.value,
    required this.icon,
    this.containerColor,
    this.valueColor,
  });

  final String value;
  final IconData icon;
  final Color? containerColor;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: containerColor ?? HexColor.fromHex("161A1F"),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: GoogleFonts.lato(color: valueColor ?? AppColors.primaryText),
          ),
          Icon(icon, color: AppColors.primaryText),
        ],
      ),
    );
  }
}
