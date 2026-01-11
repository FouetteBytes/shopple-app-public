import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/screens/onboarding/onboarding_carousel.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/dark_background/dark_radial_background.dart';
import 'package:shopple/widgets/onboarding/background_image.dart';
import 'package:shopple/widgets/onboarding/bubble.dart';
import 'package:shopple/widgets/onboarding/loading_stickers.dart';
import 'dart:math' as math;

import 'package:shopple/widgets/shapes/background_hexagon.dart';

import 'package:shopple/widgets/common/liquid_glass_button.dart';

class OnboardingStart extends StatelessWidget {
  const OnboardingStart({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions.
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          DarkRadialBackground(
            color: AppColors.background,
            position: "topLeft",
          ),

          // Background Hexagon.
          Positioned(
            top: screenHeight * 0.15,
            left: 0,
            child: Transform.rotate(
              angle: -math.pi / 2,
              child: CustomPaint(painter: BackgroundHexagon()),
            ),
          ),

          // Background images.
          Positioned(
            top: screenHeight * 0.15,
            right: screenWidth * 0.12,
            child: BackgroundImage(
              scale: 1.0,
              image: "assets/man-head.png",
              gradient: [AppColors.accentGreen, AppColors.accentGreen],
            ),
          ),

          Positioned(
            top: screenHeight * 0.28,
            left: screenWidth * 0.12,
            child: BackgroundImage(
              scale: 0.5,
              image: "assets/head_cut.png",
              gradient: [AppColors.primaryGreen, AppColors.accentGreen],
            ),
          ),

          Positioned(
            top: screenHeight * 0.38,
            right: screenWidth * 0.18,
            child: BackgroundImage(
              scale: 0.4,
              image: "assets/girl_smile.png",
              gradient: [AppColors.primaryGreen, AppColors.accentGreen],
            ),
          ),

          // Bubbles.
          Positioned(
            top: screenHeight * 0.12,
            left: screenWidth * 0.13,
            child: Bubble(1.0, AppColors.primaryGreen),
          ),

          Positioned(
            top: screenHeight * 0.17,
            left: screenWidth * 0.35,
            child: Bubble(0.6, AppColors.accentGreen),
          ),

          // Loading stickers.
          Positioned(
            top: screenHeight * 0.12,
            left: screenWidth * 0.45,
            child: LoadingSticker(
              gradients: [
                AppColors.accentGreen,
                AppColors.primaryGreen,
                AppColors.primaryGreen,
              ],
            ),
          ),

          Positioned(
            top: screenHeight * 0.30,
            left: screenWidth * 0.22,
            child: LoadingSticker(
              gradients: [AppColors.primaryGreen, AppColors.accentGreen],
            ),
          ),

          Positioned(
            top: screenHeight * 0.45,
            left: screenWidth * 0.6,
            child: LoadingSticker(
              gradients: [AppColors.primaryGreen, AppColors.accentGreen],
            ),
          ),

          // FIXED: Arrow Button - positioned like original design (bottom right area)
          Positioned(
            bottom: screenHeight * 0.28, // Slightly higher than before
            right: -screenWidth * 0.06, // NEGATIVE value to push it off-screen
            child: Transform.rotate(
              angle: -math.pi / 4,
              child: InkWell(
                onTap: () {
                  Get.to(() => OnboardingCarousel());
                },
                child: Container(
                  width: screenWidth * 0.35, // Larger size
                  height: screenWidth * 0.35, // Larger size
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(screenWidth * 0.08),
                    color: AppColors.primaryGreen,
                  ),
                  child: Transform.rotate(
                    angle: math.pi / 4,
                    child: Container(
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.arrow_forward,
                        size: screenWidth * 0.12, // Larger icon
                        color: AppColors.background,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Main Content (Bottom) - responsive positioning but same styling
          Positioned(
            bottom: screenHeight * 0.15,
            left: screenWidth * 0.1,
            child: SizedBox(
              width: screenWidth * 0.8, // Responsive width
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      text: 'Shopping Assistant ',
                      style: GoogleFonts.lato(
                        fontSize: screenWidth * 0.045, // Responsive font
                        color: AppColors.primaryGreen,
                      ),
                      children: <TextSpan>[TextSpan(text: '�')],
                    ),
                  ),
                  AppSpaces.verticalSpace20,
                  Text(
                    'Lets create\na smarter way\nto shop\nand save.',
                    style: GoogleFonts.lato(
                      color: AppColors.primaryText,
                      fontSize: screenWidth * 0.09, // Responsive font
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpaces.verticalSpace20,
                  SizedBox(
                    width: screenWidth * 0.45, // Responsive button width
                    height: screenHeight * 0.075, // Responsive button height
                    child: LiquidGlassGradientButton(
                      onTap: () {
                        Get.to(() => OnboardingCarousel());
                      },
                      gradientColors: [AppColors.primaryGreen, AppColors.primaryGreen.withValues(alpha: 0.8)],
                      borderRadius: 50.0,
                      text: 'Get Started',
                      fontSize: screenWidth * 0.05,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
