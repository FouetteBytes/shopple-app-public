// lib/theme/app_text_styles.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../values/values.dart'; 

class AppTextStyles {
  static TextStyle heading1 = GoogleFonts.poppins(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryText,
  );

  static TextStyle heading2 = GoogleFonts.poppins(
    fontSize: 34,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryText,
  );

  static TextStyle bodyL = GoogleFonts.poppins(
    fontSize: 17,
    fontWeight: FontWeight.normal,
    color: AppColors.primaryText,
  );

  static TextStyle bodyM = GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: AppColors.secondaryText,
  );

  static TextStyle button = GoogleFonts.poppins(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.background, // Black text on green button
  );
}
