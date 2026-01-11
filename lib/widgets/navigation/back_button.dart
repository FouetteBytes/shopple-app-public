import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shopple/widgets/shapes/roundedborder_with_icon.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.back();
      },
      child: RoundedBorderWithIcon(icon: Icons.arrow_back),
    );
  }
}
