import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/screens/auth/unified_email_auth.dart';
import 'package:shopple/screens/auth/phone_number.dart';
import 'package:shopple/controllers/user_controller.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/dark_background/dark_radial_background.dart';
import 'package:shopple/widgets/onboarding/travel_card_list.dart';
import 'package:shopple/data/city_data.dart';
import 'package:shopple/config/runtime_toggles.dart';
import 'dart:async';

import 'package:shopple/widgets/common/liquid_glass_button.dart';

class OnboardingCarousel extends StatefulWidget {
  const OnboardingCarousel({super.key});

  @override
  State<OnboardingCarousel> createState() => _OnboardingCarouselState();
}

class _OnboardingCarouselState extends State<OnboardingCarousel> {
  bool _isGoogleLoading = false;

  @override
  void initState() {
    super.initState();
    // Precache parallax images.
    if (!RuntimeToggles.instance.disableOnboardingPrecache.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _batchPrecacheParallaxImages();
      });
    }
  }

  static const _batchSize = 2; // Small batch size to prevent frame drops.
  static const _batchDelay = Duration(
    milliseconds: 40,
  ); // Delay between batches.
  bool _cancelPrecache = false;

  Future<void> _batchPrecacheParallaxImages() async {
    final assets = <String>[];
    for (final city in ['Pisa', 'Budapest', 'London']) {
      for (final layer in ['Back', 'Middle', 'Front']) {
        assets.add('assets/$city/$city-$layer.png');
      }
    }
    for (int i = 0; i < assets.length; i += _batchSize) {
      if (!mounted || _cancelPrecache) break;
      final slice = assets.sublist(i, (i + _batchSize).clamp(0, assets.length));
      for (final path in slice) {
        if (!context.mounted) break;
        try {
          await precacheImage(AssetImage(path), context);
        } catch (_) {}
      }
      // Yield to next frame.
      if (i + _batchSize < assets.length) {
        await Future.delayed(_batchDelay);
      }
    }
  }

  @override
  void dispose() {
    _cancelPrecache = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final bottomPadding = mediaQuery.padding.bottom;

    return Scaffold(
      appBar: null,
      extendBodyBehindAppBar: true,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          statusBarBrightness: Brightness.dark,
        ),
        child: SizedBox(
          height: screenHeight,
          width: screenWidth,
          child: Stack(
            children: [
              DarkRadialBackground(
                color: HexColor.fromHex("#181a1f"),
                position: "bottomRight",
              ),

              // Full screen layout.
              Column(
                children: [
                  // TRAVEL CARDS SECTION - 65% of screen height
                  Expanded(
                    flex: 65,
                    child: TravelCardList(
                      cities: CityData().getCities(),
                      onCityChange: (City city) {
                        // Optional: track city changes if needed
                      },
                    ),
                  ),

                  // BUTTONS SECTION - 35% of screen (responsive)
                  Expanded(
                    flex: 35,
                    child: Container(
                      width: screenWidth,
                      padding: EdgeInsets.only(
                        left: 20.0,
                        right: 20.0,
                        bottom: bottomPadding + 10,
                      ),
                      child: Column(
                        children: [
                          // Top flexible section with buttons
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  // Top spacing (responsive)
                                  SizedBox(height: screenHeight * 0.035),

                                  // 1. Email Button (Full width, responsive height) -> Sign up flow
                                  SizedBox(
                                    width: double.infinity,
                                    height:
                                        screenHeight *
                                        0.06, // 6% of screen height
                                    child: LiquidGlassGradientButton(
                                      onTap: () {
                                        // Open unified auth directly in signup mode
                                        Get.to(
                                          () => const UnifiedEmailAuthScreen(
                                            startInSignup: true,
                                          ),
                                        );
                                      },
                                      gradientColors: [
                                        HexColor.fromHex("246CFE"),
                                        HexColor.fromHex("246CFE").withValues(alpha: 0.8)
                                      ],
                                      borderRadius: 50.0,
                                      padding: EdgeInsets.zero,
                                      customChild: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.email,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              'Sign up with Email',
                                              style: GoogleFonts.lato(
                                                fontSize: 16,
                                                color: Colors.white,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Spacing between buttons (responsive)
                                  SizedBox(height: screenHeight * 0.018),

                                  // 2. Google and Phone buttons (Side by side, responsive height)
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Google Button
                                      Expanded(
                                        child: Container(
                                          height:
                                              screenHeight *
                                              0.07, // 7% of screen height
                                          margin: EdgeInsets.only(right: 10),
                                          child: LiquidGlassButton(
                                            onTap: _isGoogleLoading ? null : () async {
                                              setState(() => _isGoogleLoading = true);
                                              final UserController
                                              userController =
                                                  Get.find<UserController>();

                                              bool success =
                                                  await userController
                                                      .loginWithGoogle();

                                              if (success) {
                                                await userController
                                                    .initializeUserTracking();
                                                userController
                                                    .navigateAfterAuth();
                                              } else {
                                                if (mounted) {
                                                  setState(() => _isGoogleLoading = false);
                                                }
                                              }
                                            },
                                            borderRadius: 50.0,
                                            padding: EdgeInsets.zero,
                                            child: Center(
                                              child: _isGoogleLoading
                                                  ? SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child: CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2,
                                                      ),
                                                    )
                                                  : SizedBox(
                                                      width: 30,
                                                      height: 30,
                                                      child: ClipOval(
                                                        child: Image(
                                                          fit: BoxFit.contain,
                                                          image: AssetImage(
                                                            "assets/google_icon.png",
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Phone Button
                                      Expanded(
                                        child: Container(
                                          height:
                                              screenHeight *
                                              0.07, // 7% of screen height
                                          margin: EdgeInsets.only(left: 10),
                                          child: LiquidGlassButton(
                                            onTap: () {
                                              Get.to(() => PhoneNumberScreen());
                                            },
                                            borderRadius: 50.0,
                                            padding: EdgeInsets.zero,
                                            child: Center(
                                              child: Icon(
                                                Icons.phone,
                                                size: 24,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Spacing between buttons (responsive)
                                  SizedBox(height: screenHeight * 0.018),

                                  // Already have account button (responsive height)
                                  Container(
                                    width: double.infinity,
                                    height:
                                        screenHeight *
                                        0.055, // 5.5% of screen height
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: LiquidGlassButton.text(
                                      onTap: () {
                                        Get.to(() => UnifiedEmailAuthScreen());
                                      },
                                      text: "Already have an account?",
                                      borderRadius: 25,
                                      accentColor: AppColors.primaryGreen,
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Bottom section - Terms (always at bottom)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              'By continuing you agree to Shopple\'s Terms of Service & Privacy Policy.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                height: 1.4,
                                color: HexColor.fromHex("666A7A"),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
