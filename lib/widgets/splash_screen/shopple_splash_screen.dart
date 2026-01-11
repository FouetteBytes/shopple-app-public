import 'package:flutter/material.dart';
import 'splash_background.dart';
import 'splash_foreground.dart';

const _animationDuration = 2500;
const _fadeTransitionStart = 2100.0;
const _fadeTransitionEnd = _animationDuration;

class ShoppleSplashScreen extends StatefulWidget {
  const ShoppleSplashScreen({required this.controller, super.key});

  final AnimationController controller;

  static AnimationController createController(TickerProvider vsync) {
    return AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: _animationDuration),
    );
  }

  @override
  State<ShoppleSplashScreen> createState() => _ShoppleSplashScreenState();
}

class _ShoppleSplashScreenState extends State<ShoppleSplashScreen> {
  late final _opacity = Tween<double>(begin: 1, end: 0)
      .chain(
        CurveTween(
          curve: const Interval(
            _fadeTransitionStart / _animationDuration,
            _fadeTransitionEnd / _animationDuration,
            curve: Curves.easeOut,
          ),
        ),
      )
      .animate(widget.controller);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FadeTransition(
        opacity: _opacity,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: SplashBackground(controller: widget.controller),
              ),
            ),
            Positioned.fill(
              child: SplashForeground(controller: widget.controller),
            ),
          ],
        ),
      ),
    );
  }
}
