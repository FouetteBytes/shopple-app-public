import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/dark_background/dark_radial_background.dart';
import 'package:shopple/widgets/forms/form_input_with_label.dart';
import 'package:shopple/widgets/navigation/back.dart';
import 'package:shopple/services/auth/auth_service.dart';
import 'package:shopple/controllers/user_controller.dart';
import 'package:shopple/widgets/common/liquid_snack.dart';

class SignUp extends StatefulWidget {
  final String email;
  const SignUp({super.key, required this.email});
  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          DarkRadialBackground(
            color: HexColor.fromHex("#181a1f"),
            position: "topLeft",
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NavigationBack(),
                  SizedBox(height: 30),
                  Text(
                    'Sign Up',
                    style: GoogleFonts.lato(
                      color: AppColors.primaryText,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 15),
                  RichText(
                    text: TextSpan(
                      text: 'Using  ',
                      style: GoogleFonts.lato(
                        color: HexColor.fromHex("676979"),
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: widget.email,
                          style: TextStyle(
                            color: AppColors.primaryText70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: "  to login.",
                          style: GoogleFonts.lato(
                            color: HexColor.fromHex("676979"),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 25),
                  LabelledFormInput(
                    placeholder: "Name",
                    keyboardType: "text",
                    controller: _nameController,
                    obscureText: false,
                    label: "Your Name",
                  ),
                  SizedBox(height: 15),
                  LabelledFormInput(
                    placeholder: "Password",
                    keyboardType: "text",
                    controller: _passController,
                    obscureText: true,
                    label: "Your Password",
                  ),
                  SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_nameController.text.trim().isEmpty ||
                            _passController.text.trim().isEmpty) {
                          LiquidSnack.error(
                            title: "Error",
                            message: "Please fill all fields.",
                          );
                          return;
                        }

                        final UserController userController =
                            Get.find<UserController>();

                        bool success = await userController
                            .signUpWithEmailPassword(
                              widget.email,
                              _passController.text.trim(),
                              _nameController.text.trim(),
                            );

                        if (success) {
                          // Initialize user tracking and navigate with smart routing
                          await userController.initializeUserTracking();
                          await userController.navigateAfterAuth();
                        }
                      },
                      style: ButtonStyles.blueRounded,
                      child: Text(
                        'Sign Up',
                        style: GoogleFonts.lato(
                          fontSize: 20,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
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
                          style: GoogleFonts.lato(color: AppColors.primaryText),
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
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      icon: Icon(FontAwesomeIcons.google, color: Colors.red),
                      onPressed: () async {
                        try {
                          final userCredential = await _authService
                              .signInWithGoogle();
                          if (userCredential != null) {
                            // Use UserController for smart navigation
                            final UserController userController =
                                Get.find<UserController>();
                            await userController.initializeUserTracking();
                            await userController.navigateAfterAuth();
                          }
                        } catch (e) {
                          LiquidSnack.error(
                            title: "Google Sign-In Failed",
                            message: "An error occurred during sign-in.",
                          );
                        }
                      },
                      style: ButtonStyles.whiteRounded,
                      label: Text(
                        'Sign In with Google',
                        style: GoogleFonts.lato(
                          fontSize: 20,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20), // Extra padding at bottom
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passController.dispose();
    super.dispose();
  }
}
