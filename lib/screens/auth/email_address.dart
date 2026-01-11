import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/dark_background/dark_radial_background.dart';
import 'package:shopple/widgets/forms/form_input_with_label.dart';
import 'package:shopple/widgets/navigation/back.dart';
import 'package:shopple/widgets/shapes/background_hexagon.dart';
import 'package:shopple/screens/auth/existing_user_login.dart';

import 'signup.dart';

class EmailAddressScreen extends StatefulWidget {
  const EmailAddressScreen({super.key});

  @override
  State<EmailAddressScreen> createState() => _EmailAddressScreenState();
}

class _EmailAddressScreenState extends State<EmailAddressScreen> {
  final TextEditingController _emailController = TextEditingController();
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NavigationBack(),
                  SizedBox(height: 40),
                  Text(
                    "What's your\nemail\naddress?",
                    style: GoogleFonts.lato(
                      color: AppColors.primaryText,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpaces.verticalSpace20,
                  LabelledFormInput(
                    placeholder: "Email",
                    keyboardType: "text",
                    controller: _emailController,
                    obscureText: obscureText,
                    label: "Your Email",
                  ),
                  SizedBox(height: 40),
                  SizedBox(
                    //width: 180,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.to(() => SignUp(email: _emailController.text));
                      },
                      style: ButtonStyles.blueRounded,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.email, color: AppColors.primaryText),
                          Text(
                            '   Continue with Email',
                            style: GoogleFonts.lato(
                              fontSize: 20,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Already have account link
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Get.to(() => ExistingUserLogin());
                      },
                      child: RichText(
                        text: TextSpan(
                          text: "Already have an account? ",
                          style: GoogleFonts.lato(
                            color: HexColor.fromHex("676979"),
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: "Sign in",
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
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
