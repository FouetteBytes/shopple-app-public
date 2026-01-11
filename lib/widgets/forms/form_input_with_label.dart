// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../values/values.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/widgets/common/liquid_text_field.dart';

class LabelledFormInput extends StatelessWidget {
  final String label;
  final String placeholder;
  final String? value;
  final String keyboardType;
  final bool obscureText;
  final TextEditingController controller;
  const LabelledFormInput({
    super.key,
    required this.placeholder,
    required this.keyboardType,
    required this.controller,
    required this.obscureText,
    required this.label,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSpaces.verticalSpace10,
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.left,
          style: GoogleFonts.lato(
            fontSize: 12,
            //fontWeight: FontWeight.bold,
            color: HexColor.fromHex("3C3E49"),
          ),
        ),
        const SizedBox(height: 8),
        LiquidTextField(
          controller: controller,
          hintText: placeholder,
          keyboardType: keyboardType == "text"
              ? TextInputType.text
              : TextInputType.number,
          obscureText:
              placeholder == 'Password' || placeholder == 'Choose a password'
              ? true
              : false,
          suffixIcon: placeholder == "Password"
              ? InkWell(
                  onTap: () {},
                  child: Icon(
                    obscureText
                        ? FontAwesomeIcons.eye
                        : FontAwesomeIcons.eyeSlash,
                    //size: 15.0,
                    color: HexColor.fromHex("3C3E49"),
                  ),
                )
              : InkWell(
                  onTap: () {
                    controller.text = "";
                  },
                  child: Icon(
                    FontAwesomeIcons.solidCircleXmark,
                    size: 20,
                    color: HexColor.fromHex("3C3E49"),
                  ),
                ),
          enableBlur: false,
          accentColor: AppColors.primaryText,
          borderRadius: 12,
        ),
      ],
    );
  }
}
