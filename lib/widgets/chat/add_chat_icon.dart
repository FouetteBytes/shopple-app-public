import 'package:flutter/material.dart';
import '../../values/values.dart';
import 'package:get/get.dart';

class AppAddIcon extends StatelessWidget {
  final Widget? page;
  final Color? color;
  final double? scale;
  final VoidCallback? onTap; // allow external handlers (e.g. open create sheet)

  const AppAddIcon({super.key, this.page, this.scale, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (onTap != null) {
          onTap!();
          return;
        }
        if (page != null) Get.to(() => page!);
      },
      child: Container(
        width: 50 * (scale == null ? 1.0 : scale!),
        height: 50 * (scale == null ? 1.0 : scale!),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color ?? Colors.transparent,
          border: Border.all(
            width: 2,
            color: color ?? HexColor.fromHex("616575"),
          ),
        ),
        child: Icon(Icons.add, color: AppColors.primaryText),
      ),
    );
  }
}
