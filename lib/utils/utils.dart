import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/data/data_model.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/dummy/profile_dummy.dart';
import 'package:shopple/widgets/stacked_images.dart';

class Utils {
  // Use getters so values are fresh and safe after orientation changes.
  static double get screenWidth => Get.width;
  static double get screenHeight => Get.height;
}

class SineCurve extends Curve {
  final double count;

  const SineCurve({this.count = 3});

  @override
  double transform(double t) {
    // Normalized sine wave in [0,1]
    return sin(count * 2 * pi * t) * 0.5 + 0.5;
  }
}

Widget buildStackedImages({
  TextDirection direction = TextDirection.rtl,
  String? numberOfMembers,
  bool addMore = false,
}) {
  const double size = 50;
  const double xShift = 20;

  final lastContainer = Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: AppColors.primaryText,
      shape: BoxShape.circle,
    ),
    child: Center(
      child: Text(
        numberOfMembers ?? '',
        style: GoogleFonts.lato(
          color: HexColor.fromHex('226AFD'),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );

  final iconContainer = Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: AppColors.primaryAccentColor,
      shape: BoxShape.circle,
    ),
    child: Icon(Icons.add, color: AppColors.primaryText),
  );

  final items = List.generate(
    4,
    (index) => ProfileDummy(
      color: AppData.groupBackgroundColors[index],
      dummyType: ProfileDummyType.image,
      image: AppData.profileImages[index],
      scale: 1.0,
    ),
  );

  return StackedWidgets(
    direction: direction,
    items: [...items, lastContainer, if (addMore) iconContainer],
    size: size,
    xShift: xShift,
  );
}
