import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shopple/values/values.dart';

class LiquidNavBar extends StatelessWidget {
  final Widget child;
  final double height;

  const LiquidNavBar({
    super.key, 
    required this.child,
    this.height = 60,
  });

  @override
  Widget build(BuildContext context) {
    // Custom glass effect for Nav Bar with top rounded corners
    final borderRadius = BorderRadius.zero;

    // Use background color with transparency to match the theme but keep glass effect
    final gradientColors = [
      AppColors.background.withValues(alpha: 0.7),
      AppColors.background.withValues(alpha: 0.5),
    ];
    
    final borderColor = Colors.white.withValues(alpha: 0.1);

    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        children: [
          // Blur effect
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 20,
                sigmaY: 20,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          // Gradient and Border
          Container(
            width: double.infinity,
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border(
                top: BorderSide(color: borderColor, width: 1),
                left: BorderSide(color: borderColor, width: 1),
                right: BorderSide(color: borderColor, width: 1),
                // No bottom border as it touches the bottom of screen
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -5), // Shadow upwards
                ),
              ],
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
