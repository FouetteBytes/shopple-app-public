import 'package:flutter/material.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/chat/add_chat_icon.dart';
import 'package:shopple/widgets/dark_background/dark_radial_background.dart';
import 'package:shopple/widgets/navigation/app_header.dart';

class Projects extends StatelessWidget {
  const Projects({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          DarkRadialBackground(
            color: HexColor.fromHex("#181a1f"), // legacy exact color
            position: "topLeft",
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20, left: 20),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShoppleAppHeader(title: "Chat", widget: AppAddIcon()),
                  AppSpaces.verticalSpace20,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
