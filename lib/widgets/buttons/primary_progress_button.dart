import 'package:flutter/material.dart';
import '../../values/values.dart';
import 'package:google_fonts/google_fonts.dart';

class PrimaryProgressButton extends StatelessWidget {
  final String label;
  final double? width;
  final double? height;
  final TextStyle? textStyle;
  final VoidCallback? callback;
  const PrimaryProgressButton({
    super.key,
    required this.label,
    this.callback,
    this.width,
    this.height,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for dynamic sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return IntrinsicWidth(
      // This makes the button adjust to content size
      child: Container(
        constraints: BoxConstraints(
          minWidth:
              screenWidth * 0.15, // Reduced from 0.2 to 0.15 (smaller minimum)
          maxWidth:
              screenWidth * 0.4, // Reduced from 0.6 to 0.4 (smaller maximum)
        ),
        height:
            height ??
            screenHeight * 0.05, // Reduced from 0.07 to 0.05 (smaller height)
        child: ElevatedButton(
          onPressed: callback,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all<Color>(
              AppColors.primaryGreen,
            ),
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  screenHeight * 0.025,
                ), // Reduced from 0.035 to 0.025
                side: BorderSide(color: AppColors.primaryGreen),
              ),
            ),
            padding: WidgetStateProperty.all<EdgeInsets>(
              EdgeInsets.symmetric(
                horizontal:
                    screenWidth *
                    0.04, // Reduced from 0.06 to 0.04 (smaller padding)
                vertical:
                    screenHeight *
                    0.01, // Reduced from 0.015 to 0.01 (smaller padding)
              ),
            ),
          ),
          child: Text(
            label,
            style:
                textStyle ??
                GoogleFonts.lato(
                  fontSize: _calculateFontSize(
                    screenWidth,
                    label,
                  ), // Dynamic font size based on content
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // Helper method to calculate font size based on screen width and content length
  double _calculateFontSize(double screenWidth, String content) {
    double baseFontSize =
        screenWidth * 0.035; // Reduced from 0.045 to 0.035 (smaller base font)

    // Adjust font size based on content length
    if (content.length <= 4) {
      return baseFontSize; // Short text like "Done", "Save"
    } else if (content.length <= 8) {
      return baseFontSize * 0.9; // Medium text like "Continue"
    } else if (content.length <= 12) {
      return baseFontSize * 0.85; // Longer text like "Get Started"
    } else {
      return baseFontSize * 0.8; // Very long text
    }
  }
}
