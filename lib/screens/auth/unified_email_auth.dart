import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/dark_background/dark_radial_background.dart';
import 'package:shopple/widgets/forms/form_input_with_label.dart';
import 'package:shopple/widgets/navigation/back.dart';
import 'package:shopple/widgets/shapes/background_hexagon.dart';
import 'package:shopple/controllers/user_controller.dart';
import 'package:shopple/services/auth/auth_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shopple/widgets/common/liquid_snack.dart';

class UnifiedEmailAuthScreen extends StatefulWidget {
  /// If true, the screen opens directly in signup mode (showing name field),
  /// otherwise it defaults to login mode.
  final bool startInSignup;

  const UnifiedEmailAuthScreen({super.key, this.startInSignup = false});

  @override
  State<UnifiedEmailAuthScreen> createState() => _UnifiedEmailAuthScreenState();
}

class _UnifiedEmailAuthScreenState extends State<UnifiedEmailAuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final UserController _userController = Get.find<UserController>();
  final AuthService _authService = AuthService();

  late bool isExistingUser; // Toggle between login and signup
  late bool showNameField;
  bool _isGoogleLoading = false;

  @override
  void initState() {
    super.initState();
    // If startInSignup is true, invert existing user state.
    isExistingUser = !widget.startInSignup;
    showNameField = widget.startInSignup;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          DarkRadialBackground(
            color: HexColor.fromHex("#181a1f"),
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
          Padding(
            padding: EdgeInsets.all(20.0),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NavigationBack(),
                    SizedBox(height: 40),
                    Text(
                      isExistingUser
                          ? "Welcome\nback!"
                          : "Create your\naccount",
                      style: GoogleFonts.lato(
                        color: AppColors.primaryText,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      isExistingUser
                          ? "Sign into your Shopple account"
                          : "Join Shopple and start your journey",
                      style: GoogleFonts.lato(
                        color: HexColor.fromHex("676979"),
                        fontSize: 16,
                      ),
                    ),
                    AppSpaces.verticalSpace20,

                    // Email Input
                    LabelledFormInput(
                      placeholder: "Email",
                      keyboardType: "text",
                      controller: _emailController,
                      obscureText: false,
                      label: "Your Email",
                    ),
                    SizedBox(height: 15),

                    // Name Input (only for signup)
                    if (showNameField)
                      Column(
                        children: [
                          LabelledFormInput(
                            placeholder: "Full Name",
                            keyboardType: "text",
                            controller: _nameController,
                            obscureText: false,
                            label: "Your Name",
                          ),
                          SizedBox(height: 15),
                        ],
                      ),

                    // Password Input
                    LabelledFormInput(
                      placeholder: "Password",
                      keyboardType: "text",
                      controller: _passwordController,
                      obscureText: true,
                      label: "Your Password",
                    ),
                    SizedBox(height: 40),

                    // Primary Action Button
                    Obx(
                      () => SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _userController.isLoading
                              ? null
                              : () async {
                                  await _handlePrimaryAction();
                                },
                          style: ButtonStyles.blueRounded,
                          child: _userController.isLoading
                              ? CircularProgressIndicator(
                                  color: AppColors.primaryText,
                                  strokeWidth: 2,
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isExistingUser
                                          ? Icons.login
                                          : Icons.person_add,
                                      color: AppColors.primaryText,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      isExistingUser ? 'Sign In' : 'Sign Up',
                                      style: GoogleFonts.lato(
                                        fontSize: 20,
                                        color: AppColors.primaryText,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    SizedBox(height: 15),

                    // OR Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: AppColors.primaryText.withValues(alpha: 0.5),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            "OR",
                            style: GoogleFonts.lato(
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: AppColors.primaryText.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 15),

                    // Google Sign In Button
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        icon: _isGoogleLoading 
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.red,
                                ),
                              )
                            : Icon(FontAwesomeIcons.google, color: Colors.red),
                        onPressed: _isGoogleLoading ? null : () async {
                          await _handleGoogleSignIn();
                        },
                        style: ButtonStyles.whiteRounded,
                        label: Text(
                          _isGoogleLoading ? 'Signing in...' : 'Continue with Google',
                          style: GoogleFonts.lato(
                            fontSize: 20,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Switch between login/signup
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isExistingUser = !isExistingUser;
                            showNameField = !isExistingUser;
                            // Clear fields when switching
                            _passwordController.clear();
                            if (isExistingUser) {
                              _nameController.clear();
                            }
                          });
                        },
                        child: RichText(
                          text: TextSpan(
                            text: isExistingUser
                                ? "Don't have an account? "
                                : "Already have an account? ",
                            style: GoogleFonts.lato(
                              color: HexColor.fromHex("676979"),
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: isExistingUser ? "Sign up" : "Sign in",
                                style: GoogleFonts.lato(
                                  color: AppColors.primaryGreen,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePrimaryAction() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      LiquidSnack.error(
        title: "Error",
        message: "Please fill all required fields",
      );
      return;
    }

    if (!isExistingUser && _nameController.text.trim().isEmpty) {
      LiquidSnack.error(
        title: "Error",
        message: "Please enter your name",
      );
      return;
    }

    bool success = false;

    if (isExistingUser) {
      // Login existing user
      success = await _userController.loginWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } else {
      // Sign up new user
      success = await _userController.signUpWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
      );
    }

    if (success) {
      await _userController.initializeUserTracking();
      await _userController.navigateAfterAuth();
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential != null) {
        await _userController.initializeUserTracking();
        await _userController.navigateAfterAuth();
      } else {
        // User cancelled or sign in was aborted
        if (mounted) {
          setState(() => _isGoogleLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
      LiquidSnack.show(
        title: "Google Sign-In Failed",
        message: "An error occurred during sign-in.",
        accentColor: AppColors.error,
        icon: Icons.error_outline,
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
