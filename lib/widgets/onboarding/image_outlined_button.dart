import 'package:flutter/material.dart';
import 'package:shopple/widgets/common/liquid_glass_button.dart';

class OutlinedButtonWithImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  const OutlinedButtonWithImage({
    super.key,
    required this.imageUrl,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 60,
      child: LiquidGlassButton(
        onTap: () {},
        borderRadius: 60,
        padding: EdgeInsets.zero,
        child: Center(
          child: SizedBox(
            width: 30,
            height: 30,
            child: ClipOval(
              child: Image(fit: BoxFit.contain, image: AssetImage(imageUrl)),
            ),
          ),
        ),
      ),
    );
  }
}
