import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/dark_background/dark_radial_background.dart';
import 'package:shopple/widgets/forms/form_input_with_label.dart';
import 'package:shopple/widgets/navigation/back.dart';
import 'package:shopple/controllers/user_controller.dart';
import 'package:shopple/widgets/animations/optional_animation.dart';
import 'package:shopple/widgets/common/liquid_snack.dart';

class Login extends StatefulWidget {
  final String email;

  const Login({super.key, required this.email});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _passController = TextEditingController();
  bool obscureText = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          DarkRadialBackground(
            color: HexColor.fromHex("#181a1f"),
            position: "topLeft",
          ),
          Padding(
            padding: EdgeInsets.all(20.0),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NavigationBack(),
                  SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Login',
                          style: GoogleFonts.lato(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Optional welcoming animation
                      const OptionalAnimation(
                        asset: 'assets/animations/login_success.json',
                        width: 64,
                        height: 64,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                  AppSpaces.verticalSpace20,
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
                            color: Colors.white70,
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
                  SizedBox(height: 30),
                  // Divider-like subtle hint with small animation
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white10)),
                      const SizedBox(width: 8),
                      const OptionalAnimation(
                        asset: 'assets/animations/lock.riv',
                        width: 36,
                        height: 36,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Divider(color: Colors.white10)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LabelledFormInput(
                    placeholder: "Password",
                    keyboardType: "text",
                    controller: _passController,
                    obscureText: obscureText,
                    label: "Your Password",
                  ),
                  SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_passController.text.trim().isEmpty) {
                          LiquidSnack.show(
                            title: "Error",
                            message: "Please enter your password",
                            accentColor: AppColors.error,
                            icon: Icons.error_outline,
                          );
                          return;
                        }

                        final UserController userController =
                            Get.find<UserController>();

                        bool success = await userController
                            .loginWithEmailPassword(
                              widget.email,
                              _passController.text.trim(),
                            );

                        if (success) {
                          // Use smart navigation for existing users
                          await userController.navigateAfterAuth();
                        }
                      },
                      style: ButtonStyles.blueRounded,
                      child: Text(
                        'Sign In',
                        style: GoogleFonts.lato(
                          fontSize: 20,
                          color: Colors.white,
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
    );
  }

  @override
  void dispose() {
    _passController.dispose();
    super.dispose();
  }
}
