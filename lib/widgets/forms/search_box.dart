// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../values/values.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shopple/widgets/common/liquid_text_field.dart';

class SearchBox extends StatelessWidget {
  final String placeholder;

  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  const SearchBox({
    super.key,
    required this.placeholder,
    this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidTextField(
      controller: controller,
      onChanged: onChanged,
      hintText: placeholder,
      borderRadius: 12,
      prefixIcon: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Icon(FeatherIcons.search, color: AppColors.primaryText),
      ),
      suffixIcon: InkWell(
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
    );
  }
}
