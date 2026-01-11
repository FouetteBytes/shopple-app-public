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
import 'package:shopple/screens/auth/email_address.dart';
import 'package:shopple/widgets/animations/optional_animation.dart';
import 'package:shopple/widgets/common/liquid_snack.dart';

class ExistingUserLogin extends StatefulWidget {
  const ExistingUserLogin({super.key});

  @override
  State<ExistingUserLogin> createState() => _ExistingUserLoginState();
}

class _ExistingUserLoginState extends State<ExistingUserLogin> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final UserController _userController = Get.find<UserController>();

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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            "Welcome\nback!",
                            style: GoogleFonts.lato(
                              color: AppColors.primaryText,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const OptionalAnimation(
                          asset: 'assets/animations/hello.json',
                          width: 72,
                          height: 72,
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Sign into your Shopple account",
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

                    // Password Input
                    LabelledFormInput(
                      placeholder: "Password",
                      keyboardType: "text",
                      controller: _passwordController,
                      obscureText: true,
                      label: "Your Password",
                    ),
                    SizedBox(height: 40),

                    // Login Button
                    Obx(
                      () => SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _userController.isLoading
                              ? null
                              : () async {
                                  if (_emailController.text.trim().isEmpty ||
                                      _passwordController.text.trim().isEmpty) {
                                    LiquidSnack.show(
                                      title: "Error",
                                      message: "Please fill all fields",
                                      accentColor: AppColors.error,
                                      icon: Icons.error_outline,
                                    );
                                    return;
                                  }

                                  bool success = await _userController
                                      .loginWithEmailPassword(
                                        _emailController.text.trim(),
                                        _passwordController.text.trim(),
                                      );

                                  if (success) {
                                    // Use smart navigation for existing users
                                    await _userController.navigateAfterAuth();
                                  }
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
                                      Icons.login,
                                      color: AppColors.primaryText,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Sign In',
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

                    SizedBox(height: 20),

                    // Don't have account? Sign up link
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Get.to(() => EmailAddressScreen());
                        },
                        child: RichText(
                          text: TextSpan(
                            text: "Don't have an account? ",
                            style: GoogleFonts.lato(
                              color: HexColor.fromHex("676979"),
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: "Sign up",
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
