import 'dart:ui';
import 'package:flutter/material.dart';

/// A reusable glassmorphic surface with optional backdrop blur.
///
/// Defaults are tuned to be subtle and performant for list items.
class LiquidGlass extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool enableBlur;
  final double blurSigmaX;
  final double blurSigmaY;
  final List<Color>? gradientColors;
  final AlignmentGeometry gradientBegin;
  final AlignmentGeometry gradientEnd;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;

  const LiquidGlass({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding,
    this.enableBlur = false,
    this.blurSigmaX = 12,
    this.blurSigmaY = 18,
    this.gradientColors,
    this.gradientBegin = Alignment.topLeft,
    this.gradientEnd = Alignment.bottomRight,
    this.borderColor,
    this.borderWidth = 1,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        gradientColors ??
        [
          Colors.white.withValues(alpha: 0.07),
          Colors.white.withValues(alpha: 0.03),
        ];
    final borderClr = borderColor ?? Colors.white.withValues(alpha: 0.08);
    final shadows =
        boxShadow ??
        [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ];

    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: gradientBegin,
          end: gradientEnd,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderClr, width: borderWidth),
        boxShadow: shadows,
      ),
      child: child,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: enableBlur
          ? Stack(
              children: [
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: blurSigmaX,
                      sigmaY: blurSigmaY,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
                content,
              ],
            )
          : content,
    );
  }
}
