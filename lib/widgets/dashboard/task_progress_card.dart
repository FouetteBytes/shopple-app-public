import 'package:flutter/material.dart';
import '../../values/values.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/constants/constants.dart';
import 'package:shopple/widgets/buttons/progress_card_close_button.dart';

class TaskProgressCard extends StatelessWidget {
  final String cardTitle;
  final String rating;
  final String progressFigure;
  final int percentageGap;
  const TaskProgressCard({
    super.key,
    required this.rating,
    required this.cardTitle,
    required this.progressFigure,
    required this.percentageGap,
  });

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for dynamic sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.18, // Dynamic height
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: screenWidth * 0.01, // Dynamic blur radius
            offset: Offset(
              screenWidth * 0.01,
              screenHeight * 0.01,
            ), // Dynamic offset
          ),
        ],
        borderRadius: BorderRadius.circular(
          screenWidth * 0.05,
        ), // Dynamic border radius
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [...progressCardGradientList],
        ),
      ),
      child: Stack(
        children: [
          // Close button - dynamic positioning
          Positioned(
            top: screenHeight * 0.01, // Dynamic top position
            right: screenWidth * 0.025, // Dynamic right position
            child: ProgressCardCloseButton(),
          ),

          // Main content - reduced padding to prevent overflow
          Padding(
            padding: EdgeInsets.only(
              top: screenHeight * 0.015, // Reduced from 0.02
              bottom: screenHeight * 0.015, // Reduced from 0.02
              left: screenWidth * 0.05, // Keep same
              right: screenWidth * 0.13, // Keep same for close button
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly, // Changed to spaceEvenly
              children: [
                // Title - dynamic font size with Flexible
                Flexible(
                  flex: 2, // Give more space to title
                  child: Text(
                    cardTitle,
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.04, // Reduced from 0.045
                      color: Colors.black,
                      shadows: [
                        Shadow(
                          offset: Offset(
                            screenWidth * 0.001,
                            screenWidth * 0.001,
                          ),
                          blurRadius: screenWidth * 0.002,
                          color: AppColors.secondaryText,
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),

                // Rating text - dynamic font size with Flexible
                Flexible(
                  flex: 1, // Give less space to rating
                  child: Text(
                    '$rating is completed',
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.w500,
                      fontSize: screenWidth * 0.032, // Reduced from 0.035
                      color: Colors.black87,
                      shadows: [
                        Shadow(
                          offset: Offset(
                            screenWidth * 0.001,
                            screenWidth * 0.001,
                          ),
                          blurRadius: screenWidth * 0.002,
                          color: AppColors.secondaryText,
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),

                // Progress bar row - dynamic sizing with Flexible
                Flexible(
                  flex: 1, // Give appropriate space to progress bar
                  child: Row(
                    children: [
                      // Progress bar - takes available space
                      Expanded(
                        child: Container(
                          height: screenHeight * 0.008, // Reduced from 0.01
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(
                              Radius.circular(screenWidth * 0.04),
                            ), // Reduced radius
                            color: AppColors.primaryText.withValues(alpha: 0.5),
                          ),
                          child: Row(
                            children: [
                              // Filled portion - use progressFigure
                              Expanded(
                                flex: double.parse(progressFigure).round(),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(
                                        screenWidth * 0.04,
                                      ),
                                      bottomLeft: Radius.circular(
                                        screenWidth * 0.04,
                                      ),
                                      topRight:
                                          double.parse(progressFigure) >= 100
                                          ? Radius.circular(screenWidth * 0.04)
                                          : Radius.zero,
                                      bottomRight:
                                          double.parse(progressFigure) >= 100
                                          ? Radius.circular(screenWidth * 0.04)
                                          : Radius.zero,
                                    ),
                                  ),
                                ),
                              ),
                              // Empty portion
                              Expanded(
                                flex:
                                    100 - double.parse(progressFigure).round(),
                                child: Container(),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Dynamic spacing
                      SizedBox(width: screenWidth * 0.02), // Reduced from 0.025
                      // Percentage text - dynamic font size
                      Text(
                        "$progressFigure%",
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.028, // Reduced from 0.03
                          color: Colors.black,
                          shadows: [
                            Shadow(
                              offset: Offset(
                                screenWidth * 0.001,
                                screenWidth * 0.001,
                              ),
                              blurRadius: screenWidth * 0.002,
                              color: AppColors.secondaryText,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
