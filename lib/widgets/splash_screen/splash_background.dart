import 'package:flutter/material.dart';
import 'package:shopple/values/values.dart';
import 'package:google_fonts/google_fonts.dart';

const _animationDuration = 2500;
const _textFadeOutStart = 950.0; // Start fading when icon begins enlarging
const _textFadeOutEnd = 1400.0; // Complete fade before icon finishes enlarging

class SplashBackground extends StatelessWidget {
  const SplashBackground({this.controller, super.key});

  final AnimationController? controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Use app theme colors for background to contrast with foreground reveal
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryBackgroundColor,
                AppColors.darkGreenBackground,
              ],
            ),
          ),
        ),
        // Center the Shopple text with fade-out animation
        Center(
          child: controller != null
              ? AnimatedShoppleText(controller: controller!)
              : ShoppleText(),
        ),
      ],
    );
  }
}

class ShoppleText extends StatelessWidget {
  const ShoppleText({super.key});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: 'Shopple',
        style: GoogleFonts.lato(
          fontSize: 48,
          color: Colors.white,
          fontWeight: FontWeight.bold, // Made bold as requested
          letterSpacing: 1.2,
        ),
        children: <TextSpan>[
          TextSpan(
            text: '.',
            style: TextStyle(
              color: AppColors.primaryAccentColor,
              fontWeight: FontWeight.bold,
              fontSize: 48,
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedShoppleText extends StatefulWidget {
  const AnimatedShoppleText({required this.controller, super.key});

  final AnimationController controller;

  @override
  State<AnimatedShoppleText> createState() => _AnimatedShoppleTextState();
}

class _AnimatedShoppleTextState extends State<AnimatedShoppleText> {
  late final _textOpacity = Tween<double>(begin: 1, end: 0)
      .chain(
        CurveTween(
          curve: const Interval(
            _textFadeOutStart / _animationDuration,
            _textFadeOutEnd / _animationDuration,
            curve: Curves.easeOut,
          ),
        ),
      )
      .animate(widget.controller);

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _textOpacity, child: ShoppleText());
  }
}
