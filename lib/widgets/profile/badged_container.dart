import 'package:flutter/material.dart';
import '../../values/values.dart';
import 'package:google_fonts/google_fonts.dart';

class BadgedContainer extends StatelessWidget {
  final String label;
  final String value;
  final String badgeColor;
  final VoidCallback? callback;

  const BadgedContainer({
    super.key,
    required this.label,
    required this.value,
    required this.badgeColor,
    this.callback,
  });

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for dynamic sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return InkWell(
      onTap: callback,
      child: Container(
        width: double.infinity,
        height:
            screenHeight * 0.085, // Reduced from 0.11 to 0.085 (smaller height)
        padding: EdgeInsets.all(
          screenWidth * 0.04,
        ), // Reduced from 0.05 to 0.04 (smaller padding)
        decoration: BoxDecoration(
          color: AppColors.primaryBackgroundColor,
          borderRadius: BorderRadius.circular(
            screenWidth * 0.02,
          ), // Reduced from 0.025 to 0.02
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Keep original alignment
          children: [
            Container(
              width:
                  screenWidth *
                  0.1, // Reduced from 0.125 to 0.1 (smaller circle)
              height: screenWidth * 0.1, // Keep it square
              decoration: BoxDecoration(
                color: HexColor.fromHex("A06AFA"),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.do_not_disturb,
                color: AppColors.primaryText,
                size:
                    screenWidth *
                    0.06, // Reduced from 0.075 to 0.06 (smaller icon)
              ),
            ),
            SizedBox(
              width: screenWidth * 0.04,
            ), // Reduced from 0.05 to 0.04 (smaller spacing)
            Expanded(
              child: IntrinsicHeight(
                // Keep original wrapper
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start, // Keep original alignment
                  mainAxisAlignment: MainAxisAlignment
                      .spaceEvenly, // Keep original distribution
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.lato(
                        color: AppColors.primaryText,
                        fontSize:
                            screenWidth *
                            0.038, // Reduced from 0.043 to 0.038 (smaller font)
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    (value == "Off")
                        ? Text(
                            value,
                            style: GoogleFonts.lato(
                              fontWeight: FontWeight.bold,
                              color: HexColor.fromHex("5E6272"),
                              fontSize:
                                  screenWidth *
                                  0.033, // Reduced from 0.038 to 0.033 (smaller font)
                            ),
                          )
                        : Container(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  screenWidth *
                                  0.02, // Reduced from 0.025 to 0.02
                              vertical:
                                  screenHeight *
                                  0.001, // Reduced from 0.002 to 0.001
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.04,
                              ), // Reduced from 0.05 to 0.04
                              color: HexColor.fromHex(badgeColor),
                            ),
                            child: Text(
                              value,
                              style: GoogleFonts.lato(
                                fontWeight: FontWeight.bold,
                                fontSize:
                                    screenWidth *
                                    0.033, // Reduced from 0.038 to 0.033 (smaller font)
                                color: AppColors.primaryText,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
