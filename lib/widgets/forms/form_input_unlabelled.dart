// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../values/values.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shopple/widgets/common/liquid_text_field.dart';

class UnlabelledFormInput extends StatelessWidget {
  final String placeholder;
  final String keyboardType;
  final bool? autofocus;
  final bool obscureText;
  final TextEditingController? controller;
  const UnlabelledFormInput({
    super.key,
    this.autofocus,
    required this.placeholder,
    required this.keyboardType,
    this.controller,
    required this.obscureText,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidTextField(
      controller: controller,
      autofocus: autofocus ?? false,
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
                size: 15.0,
                color: HexColor.fromHex("3C3E49"),
              ),
            )
          : InkWell(
              onTap: () {
                controller?.text = "";
              },
              child: Icon(
                FontAwesomeIcons.solidCircleXmark,
                color: AppColors.primaryText.withValues(alpha: 0.7),
                size: 20,
              ),
            ),
      enableBlur: false,
      accentColor: AppColors.primaryText,
      borderRadius: 12,
    );
  }
}
