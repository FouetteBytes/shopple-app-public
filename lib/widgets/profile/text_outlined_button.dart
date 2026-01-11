import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';

class OutlinedButtonWithText extends StatelessWidget {
  final String content;
  final double? width; // Make it optional
  final VoidCallback? onPressed;

  const OutlinedButtonWithText({
    super.key,
    required this.content,
    this.width,
    this.onPressed,
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
          minWidth: screenWidth * 0.2, // Minimum width (20% of screen)
          maxWidth: screenWidth * 0.5, // Maximum width (50% of screen)
        ),
        height: screenHeight * 0.055, // Dynamic height (5.5% of screen height)
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent, // Transparent background
            side: BorderSide(
              color: HexColor.fromHex("246EFE"), // Keep the blue border
              width: 2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                screenHeight * 0.03,
              ), // Dynamic border radius
            ),
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.06, // Dynamic horizontal padding
              vertical: screenHeight * 0.01, // Dynamic vertical padding
            ),
          ),
          child: Text(
            content,
            style: GoogleFonts.lato(
              // Use GoogleFonts for consistency
              fontSize: _calculateFontSize(
                screenWidth,
                content,
              ), // Dynamic font size based on content
              color: HexColor.fromHex("246EFE"), // Match the border color
              fontWeight: FontWeight.w600, // Semi-bold
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // Helper method to calculate font size based on screen width and content length
  double _calculateFontSize(double screenWidth, String content) {
    double baseFontSize = screenWidth * 0.04; // Base 4% of screen width

    // Adjust font size based on content length
    if (content.length <= 4) {
      return baseFontSize; // Short text like "Edit"
    } else if (content.length <= 8) {
      return baseFontSize * 0.9; // Medium text
    } else {
      return baseFontSize * 0.8; // Long text
    }
  }
}
