import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shopple/widgets/common/liquid_snack.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/dark_background/dark_radial_background.dart';
import 'package:shopple/widgets/navigation/back.dart';
import 'package:shopple/controllers/user_controller.dart';
import 'dart:math' as math;
import 'package:shopple/widgets/shapes/background_hexagon.dart';
import 'package:shopple/widgets/common/liquid_glass_button.dart';

class PhoneOtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const PhoneOtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  State<PhoneOtpVerificationScreen> createState() =>
      _PhoneOtpVerificationScreenState();
}

class _PhoneOtpVerificationScreenState
    extends State<PhoneOtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final UserController _userController = UserController.instance;
  String _otpCode = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          statusBarBrightness: Brightness.dark,
        ),
        child: Stack(
          children: [
            DarkRadialBackground(
              color: AppColors.background,
              position: "topLeft",
            ),
            Positioned(
              top: Utils.screenHeight / 2,
              left: Utils.screenWidth,
              child: Transform.rotate(
                angle: -math.pi / 2,
                child: CustomPaint(painter: BackgroundHexagon()),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NavigationBack(),
                    SizedBox(height: 40),

                    // Title
                    Text(
                      "Enter the\nverification\ncode",
                      style: GoogleFonts.lato(
                        color: AppColors.primaryText,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 16),

                    // Phone number display
                    Text(
                      'We sent a code to ${_maskPhoneNumber(widget.phoneNumber)}',
                      style: GoogleFonts.lato(
                        color: AppColors.primaryText70,
                        fontSize: 16,
                      ),
                    ),

                    SizedBox(height: 40),

                    // OTP Input
                    PinCodeTextField(
                      appContext: context,
                      length: 6,
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textStyle: GoogleFonts.lato(
                        color: AppColors.primaryText,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(12),
                        fieldHeight: 56,
                        fieldWidth: 48,
                        activeFillColor: AppColors.surface,
                        inactiveFillColor: AppColors.surface,
                        selectedFillColor: AppColors.surface,
                        activeColor: AppColors.primaryAccentColor,
                        inactiveColor: AppColors.inactive.withValues(
                          alpha: 0.3,
                        ),
                        selectedColor: AppColors.primaryAccentColor,
                      ),
                      enableActiveFill: true,
                      onChanged: (value) {
                        // Check if widget is still mounted to prevent disposed controller usage
                        if (!mounted) return;

                        setState(() {
                          _otpCode = value;
                        });
                      },
                      onCompleted: (value) {
                        // Check if widget is still mounted before verification
                        if (!mounted) return;
                        _verifyOtp(value);
                      },
                    ),

                    SizedBox(height: 40),

                    // Verify button
                    Obx(
                      () => SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: LiquidGlassGradientButton(
                          onTap: (_otpCode.length == 6 && !_userController.isLoading)
                              ? () => _verifyOtp(_otpCode)
                              : null,
                          gradientColors: _otpCode.length == 6
                              ? [AppColors.primaryAccentColor, AppColors.primaryAccentColor.withValues(alpha: 0.8)]
                              : [AppColors.inactive, AppColors.inactive.withValues(alpha: 0.8)],
                          borderRadius: 50.0,
                          isDisabled: !(_otpCode.length == 6 && !_userController.isLoading),
                          customChild: Center(
                            child: _userController.isLoading
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: AppColors.primaryText,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Verify Code',
                                    style: GoogleFonts.lato(
                                      fontSize: 18,
                                      color: AppColors.primaryText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Resend code
                    Center(
                      child: Obx(() {
                        int countdown = _userController.otpCountdown;
                        return countdown > 0
                            ? Text(
                                'Resend code in ${countdown}s',
                                style: GoogleFonts.lato(
                                  color: AppColors.inactive,
                                  fontSize: 14,
                                ),
                              )
                            : GestureDetector(
                                onTap: _userController.isLoading
                                    ? null
                                    : _resendOtp,
                                child: Text(
                                  'Didn\'t receive the code? Resend',
                                  style: GoogleFonts.lato(
                                    color: AppColors.primaryAccentColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              );
                      }),
                    ),

                    SizedBox(height: 20),

                    // Wrong number
                    Center(
                      child: GestureDetector(
                        onTap: () => Get.back(),
                        child: Text(
                          'Wrong number? Go back',
                          style: GoogleFonts.lato(
                            color: AppColors.primaryText70,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
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

  String _maskPhoneNumber(String phoneNumber) {
    if (phoneNumber.length < 4) return phoneNumber;

    String lastFour = phoneNumber.substring(phoneNumber.length - 4);
    String masked = phoneNumber
        .substring(0, phoneNumber.length - 4)
        .replaceAll(RegExp(r'\d'), '*');
    return masked + lastFour;
  }

  void _verifyOtp(String otpCode) async {
    // Check if widget is still mounted before starting verification
    if (!mounted) return;

    if (otpCode.length != 6) {
      LiquidSnack.error(
        title: 'Invalid Code',
        message: 'Please enter a valid 6-digit verification code',
      );
      return;
    }

    try {
      await _userController.verifyOtpCode(otpCode);
    } catch (e) {
      // Error is handled by UserController
      // Clear the OTP field on error only if widget is still mounted
      if (mounted) {
        try {
          _otpController.clear();
          setState(() {
            _otpCode = '';
          });
        } catch (e) {
          // Safe: controller may be disposed
        }
      }
    }
  }

  void _resendOtp() async {
    if (!mounted) return;

    try {
      await _userController.resendOtp();
      if (mounted) {
        try {
          _otpController.clear();
          setState(() {
            _otpCode = '';
          });
        } catch (e) {
          // Safe: controller may be disposed
        }
      }
    } catch (e) {
      // Error is handled by UserController
    }
  }

  @override
  void dispose() {
    try {
      _otpController.dispose();
    } catch (e) {
      // Controller might already be disposed, ignore
    }
    super.dispose();
  }
}
