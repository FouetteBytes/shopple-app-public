import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../values/values.dart';

/// Reusable header widget with title and customizable action buttons
/// Extracted from FriendsScreen._buildHeader for consistency across screens
class PageHeader extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? titleColor;

  const PageHeader({
    super.key,
    required this.title,
    this.actions,
    this.fontSize = 32,
    this.fontWeight = FontWeight.bold,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.lato(
              color: titleColor ?? AppColors.primaryText,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          ),
        ),
        if (actions != null && actions!.isNotEmpty) Row(children: actions!),
      ],
    );
  }
}

/// Helper class to create standardized action buttons for PageHeader
class PageHeaderAction {
  /// Creates a standard icon button with consistent styling
  static Widget iconButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
    Color? color,
  }) {
    return IconButton(
      icon: Icon(icon, color: color ?? AppColors.primaryAccentColor),
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }
}
