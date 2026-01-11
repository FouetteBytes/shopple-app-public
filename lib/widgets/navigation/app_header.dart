import 'package:flutter/material.dart';
import '../../values/values.dart';
import 'package:google_fonts/google_fonts.dart';

import 'back_button.dart';

class ShoppleAppHeader extends StatelessWidget {
  final String title;
  final bool? messagingPage;
  final Widget? widget;
  const ShoppleAppHeader({
    super.key,
    this.widget,
    required this.title,
    this.messagingPage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppBackButton(),
        (messagingPage != null)
            ? Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: HexColor.fromHex("94D57B"),
                    ),
                  ),
                  SizedBox(width: 5),
                  Text(
                    title,
                    style: GoogleFonts.lato(
                      fontSize: 20,
                      color: AppColors.primaryText,
                    ),
                  ),
                ],
              )
            : Text(
                title,
                style: GoogleFonts.lato(
                  fontSize: 20,
                  color: AppColors.primaryText,
                ),
              ),
        widget!,
      ],
    );
  }
}
