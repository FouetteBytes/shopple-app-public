import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/dark_background/dark_radial_background.dart';
import 'package:shopple/widgets/navigation/back.dart';
import 'package:shopple/controllers/user_controller.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:shopple/widgets/shapes/background_hexagon.dart';
import 'package:shopple/widgets/common/liquid_snack.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final UserController _userController = UserController.instance;

  Timer? _verificationCheckTimer;
  bool _isChecking = false;
  int _resendCountdown = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
    _startResendCountdown();
  }

  @override
  void dispose() {
    _verificationCheckTimer?.cancel();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startVerificationCheck() {
    // Check verification status every 3 seconds
    _verificationCheckTimer = Timer.periodic(Duration(seconds: 3), (
      timer,
    ) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _isChecking = true;
      });

      bool isVerified = await _userController.checkEmailVerification();

      setState(() {
        _isChecking = false;
      });

      if (isVerified) {
        timer.cancel();
        LiquidSnack.show(
          title: 'Email Verified',
          message: 'Your email has been successfully verified!',
          accentColor: AppColors.primaryAccentColor,
          icon: Icons.check_circle_outline,
        );

        // Navigate to next step
        await _userController.navigateAfterAuth();
      }
    });
  }

  void _startResendCountdown() {
    _resendCountdown = 60;
    _resendTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

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
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom -
                          40,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          NavigationBack(),
                          SizedBox(height: 40),

                          // Title
                          Text(
                            "Verify your\nemail address",
                            style: GoogleFonts.lato(
                              color: AppColors.primaryText,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 30),

                          // Email verification icon
                          Center(
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.surface,
                                border: Border.all(
                                  color: AppColors.primaryAccentColor,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.mark_email_unread,
                                size: 60,
                                color: AppColors.primaryAccentColor,
                              ),
                            ),
                          ),

                          SizedBox(height: 30),

                          // Email display
                          Center(
                            child: Text(
                              'We sent a verification link to:',
                              style: GoogleFonts.lato(
                                color: AppColors.primaryText70,
                                fontSize: 16,
                              ),
                            ),
                          ),

                          SizedBox(height: 8),

                          Center(
                            child: Text(
                              _maskEmail(widget.email),
                              style: GoogleFonts.lato(
                                color: AppColors.primaryText,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          SizedBox(height: 30),

                          // Checking status
                          if (_isChecking)
                            Center(
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: AppColors.primaryAccentColor,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Checking verification status...',
                                    style: GoogleFonts.lato(
                                      color: AppColors.primaryText70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          SizedBox(height: 40),

                          // Instructions
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.inactive.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Please follow these steps:',
                                  style: GoogleFonts.lato(
                                    color: AppColors.primaryText,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 12),
                                _buildInstructionItem(
                                  '1. Check your email inbox',
                                ),
                                _buildInstructionItem(
                                  '2. Look for email from Shopple',
                                ),
                                _buildInstructionItem(
                                  '3. Click the verification link',
                                ),
                                _buildInstructionItem('4. Return to this app'),
                                SizedBox(height: 8),
                                Text(
                                  'Don\'t forget to check your spam folder!',
                                  style: GoogleFonts.lato(
                                    color: AppColors.inactive,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 40),

                          // Flexible spacing to push buttons to bottom on larger screens
                          SizedBox(
                            height: MediaQuery.of(context).size.height > 700
                                ? 60
                                : 20,
                          ),

                          // Resend button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed:
                                  (_resendCountdown == 0 &&
                                      !_userController.isLoading)
                                  ? _resendVerification
                                  : null,
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all(
                                  _resendCountdown == 0
                                      ? AppColors.surface
                                      : AppColors.inactive.withValues(
                                          alpha: 0.3,
                                        ),
                                ),
                                shape:
                                    WidgetStateProperty.all<
                                      RoundedRectangleBorder
                                    >(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          50.0,
                                        ),
                                        side: BorderSide(
                                          color: _resendCountdown == 0
                                              ? AppColors.primaryAccentColor
                                              : AppColors.inactive,
                                        ),
                                      ),
                                    ),
                              ),
                              child: _userController.isLoading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: AppColors.primaryText,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _resendCountdown > 0
                                          ? 'Resend in ${_resendCountdown}s'
                                          : 'Resend Verification Email',
                                      style: GoogleFonts.lato(
                                        fontSize: 16,
                                        color: _resendCountdown == 0
                                            ? AppColors.primaryAccentColor
                                            : AppColors.inactive,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),

                          SizedBox(height: 16),

                          // Skip for now
                          Center(
                            child: GestureDetector(
                              onTap: _skipVerification,
                              child: Text(
                                'Skip verification for now',
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryAccentColor,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.lato(
                color: AppColors.primaryText70,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _maskEmail(String email) {
    if (!email.contains('@')) return email;

    List<String> parts = email.split('@');
    String username = parts[0];
    String domain = parts[1];

    if (username.length <= 2) return email;

    String maskedUsername =
        username[0] +
        '*' * (username.length - 2) +
        username[username.length - 1];

    return '$maskedUsername@$domain';
  }

  void _resendVerification() async {
    try {
      await _userController.sendEmailVerification();
      _startResendCountdown();
    } catch (e) {
      // Error handled by UserController
    }
  }

  void _skipVerification() async {
    // Navigate to next step without verification
    await _userController.navigateAfterAuth();
  }
}
