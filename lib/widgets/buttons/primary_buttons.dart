import 'package:flutter/material.dart';
import '../../values/values.dart';
import 'package:google_fonts/google_fonts.dart';

enum PrimaryButtonSizes { small, medium, large }

class AppPrimaryButton extends StatelessWidget {
  final double buttonHeight;
  final double buttonWidth;

  final String buttonText;
  final VoidCallback? callback;
  const AppPrimaryButton({
    super.key,
    this.callback,
    required this.buttonText,
    required this.buttonHeight,
    required this.buttonWidth,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      //padding: EdgeInsets.all(20),
      // width: 180,
      // height: 50,
      width: buttonWidth,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: callback,
        style: ButtonStyles.blueRounded,
        child: Text(
          buttonText,
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
      ),
    );
  }
}
