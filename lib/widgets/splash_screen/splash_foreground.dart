import 'package:flutter/material.dart';
import 'package:shopple/values/values.dart';
import 'splash_painters.dart';
import 'splash_clippers.dart';

const _animationDuration = 2500;

const _frontTrackProgressStart = 0.0;
const _frontTrackProgressEnd = 1700.0;

const _frontTrackExpansionStart = 900.0;
const _frontTrackExpansionEnd = 1950.0;

const _frontTrackHeadExpansionStart = 950.0;
const _frontTrackHeadExpansionEnd = 1700.0;

const _backTrackProgressStart = 0.0;
const _backTrackProgressEnd = 850.0;

class SplashForeground extends StatefulWidget {
  const SplashForeground({required this.controller, super.key});

  final AnimationController controller;

  @override
  State<SplashForeground> createState() => _SplashForegroundState();
}

class _SplashForegroundState extends State<SplashForeground> {
  late final _frontTrackProgress = Tween<double>(begin: 0, end: 1)
      .chain(
        CurveTween(
          curve: const Interval(
            _frontTrackProgressStart / _animationDuration,
            _frontTrackProgressEnd / _animationDuration,
            curve: Curves.easeIn,
          ),
        ),
      )
      .animate(widget.controller);

  late final _frontTrackExpansion = Tween<double>(begin: 0, end: 1.15)
      .chain(
        CurveTween(
          curve: const Interval(
            _frontTrackExpansionStart / _animationDuration,
            _frontTrackExpansionEnd / _animationDuration,
            curve: Curves.easeInCirc,
          ),
        ),
      )
      .animate(widget.controller);

  late final _frontTrackHeadExpansion = Tween<double>(begin: 0, end: 1)
      .chain(
        CurveTween(
          curve: const Interval(
            _frontTrackHeadExpansionStart / _animationDuration,
            _frontTrackHeadExpansionEnd / _animationDuration,
          ),
        ),
      )
      .animate(widget.controller);

  late final _backTrackProgress = Tween<double>(begin: 0, end: 0.31)
      .chain(
        CurveTween(
          curve: const Interval(
            _backTrackProgressStart / _animationDuration,
            _backTrackProgressEnd / _animationDuration,
            curve: Cubic(0, 0, 0.63, 0.83),
          ),
        ),
      )
      .animate(widget.controller);

  late final _imageScale = Tween<double>(
    begin: 1,
    end: 1.25,
  ).chain(CurveTween(curve: Curves.linear)).animate(widget.controller);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Back track (dark background track)
        Positioned.fill(
          child: CustomPaint(
            painter: TrackPainter(progress: _backTrackProgress),
          ),
        ),
        // Clipped foreground with shopple_foreground.png
        Positioned.fill(
          child: ClipPath(
            clipper: TrackClipper(
              progress: _frontTrackProgress,
              expansion: _frontTrackExpansion,
            ),
            child: AnimatedBuilder(
              animation: _imageScale,
              builder: (context, child) {
                return Transform.scale(scale: _imageScale.value, child: child);
              },
              child: ForegroundImage(),
            ),
          ),
        ),
        // Expanding app icon at track head with shopple assets
        Center(
          child: CustomSingleChildLayout(
            delegate: IconPositionDelegate(
              progress: _frontTrackProgress,
              expansion: _frontTrackHeadExpansion,
            ),
            child: ShoppleIconCircle(),
          ),
        ),
      ],
    );
  }
}

class ForegroundImage extends StatelessWidget {
  const ForegroundImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icon/shopple_foreground.png',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        // Comprehensive fallback to themed gradient if asset fails
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryAccentColor.withValues(alpha: 0.1),
                AppColors.lightMauveBackgroundColor.withValues(alpha: 0.2),
              ],
            ),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.storefront_outlined,
                size: 80,
                color: AppColors.primaryAccentColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

class ShoppleIconCircle extends StatelessWidget {
  const ShoppleIconCircle({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ClipOval(
        child: Stack(
          children: [
            // Background circle with shopple_background.png
            Image.asset(
              'assets/icon/shopple_background.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to accent color if asset fails
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccentColor,
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
            // Centered icon with shopple_foreground.png
            Center(
              child: Padding(
                padding: const EdgeInsets.all(
                  20,
                ), // Add some padding from circle edge
                child: Image.asset(
                  'assets/icon/shopple_foreground.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to shopping bag icon if asset fails
                    return Icon(
                      Icons.shopping_bag_outlined,
                      size: 40,
                      color: Colors.white,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
