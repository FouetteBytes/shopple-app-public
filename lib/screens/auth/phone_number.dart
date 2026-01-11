import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/widgets/themed_intl_phone_field.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/dark_background/dark_radial_background.dart';
import 'package:shopple/widgets/navigation/back.dart';
import 'package:shopple/controllers/user_controller.dart';
import 'package:shopple/screens/auth/phone_otp_verification.dart';
import 'package:shopple/widgets/common/liquid_snack.dart';
import 'dart:math' as math;
import 'package:shopple/widgets/shapes/background_hexagon.dart';

class PhoneNumberScreen extends StatefulWidget {
  const PhoneNumberScreen({super.key});

  @override
  State<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final UserController _userController = UserController.instance;
  String _completePhoneNumber = '';
  bool _isValidPhone = false;

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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final viewInsets = MediaQuery.of(context).viewInsets.bottom;
                  final availableHeight = constraints.maxHeight;
                  // Dynamic spacing that shrinks when vertical space is tight
                  double topGap = availableHeight > 650 ? 40 : 24;
                  double afterFieldGap = availableHeight > 650 ? 40 : 28;
                  double titleFont = availableHeight > 650 ? 40 : 32;
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: viewInsets + 32),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          NavigationBack(),
                          SizedBox(height: topGap),
                          Text(
                            "What's your\nphone\nnumber?",
                            style: GoogleFonts.lato(
                              color: AppColors.primaryText,
                              fontSize: titleFont,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          AppSpaces.verticalSpace20,
                          ThemedIntlPhoneField(
                            controller: _phoneController,
                            hintText: 'Phone Number',
                            initialCountryCode: 'US',
                            showDropdownIcon: false,
                            onChanged: (phone) {
                              if (!mounted) return;
                              setState(() {
                                _completePhoneNumber = phone.completeNumber;
                                try {
                                  _isValidPhone =
                                      phone.number.length >= 7 &&
                                      phone.isValidNumber();
                                } catch (_) {
                                  _isValidPhone = false;
                                }
                              });
                            },
                            validator: PhoneValidationUtils.validatePhoneNumber,
                          ),
                          SizedBox(height: afterFieldGap),
                          Obx(
                            () => SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton(
                                onPressed:
                                    (_isValidPhone &&
                                        !_userController.isLoading)
                                    ? _sendOtp
                                    : null,
                                style: ButtonStyle(
                                  backgroundColor: WidgetStateProperty.all(
                                    _isValidPhone
                                        ? AppColors.primaryAccentColor
                                        : AppColors.inactive,
                                  ),
                                  shape:
                                      WidgetStateProperty.all<
                                        RoundedRectangleBorder
                                      >(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            50.0,
                                          ),
                                        ),
                                      ),
                                ),
                                child: _userController.isLoading
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: AppColors.primaryText,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.phone,
                                              color: AppColors.primaryText,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Send Verification Code',
                                              style: GoogleFonts.lato(
                                                fontSize: 18,
                                                color: AppColors.primaryText,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'We\'ll send you a verification code via SMS to verify your phone number.',
                            textAlign: TextAlign.start,
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              color: AppColors.primaryText70,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'By continuing you agree shopple\'s Terms of Services & Privacy Policy.',
                            textAlign: TextAlign.start,
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              color: AppColors.inactive,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendOtp() async {
    if (_completePhoneNumber.isEmpty || !_isValidPhone) {
      LiquidSnack.show(
        title: 'Invalid Phone Number',
        message: 'Please enter a valid phone number',
        accentColor: Colors.red,
        icon: Icons.error_outline,
      );
      return;
    }

    try {
      await _userController.sendOtpToPhone(_completePhoneNumber);

      // Navigate to OTP verification screen
      Get.to(
        () => PhoneOtpVerificationScreen(phoneNumber: _completePhoneNumber),
      );
    } catch (e) {
      // Error is handled by UserController
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
