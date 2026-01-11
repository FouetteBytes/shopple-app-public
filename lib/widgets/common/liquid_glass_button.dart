import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A glassmorphic button with liquid glass styling.
/// Reusable across the app for consistent button styling.
class LiquidGlassButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? accentColor;
  final Color? borderColor;
  final bool enableBlur;
  final bool isDestructive;
  final bool isDisabled;
  final double? width;
  final double? height;

  const LiquidGlassButton({
    super.key,
    required this.onTap,
    required this.child,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.accentColor,
    this.borderColor,
    this.enableBlur = true,
    this.isDestructive = false,
    this.isDisabled = false,
    this.width,
    this.height,
  });

  /// Factory for icon-only buttons (small, circular)
  factory LiquidGlassButton.icon({
    Key? key,
    required VoidCallback? onTap,
    required IconData icon,
    double size = 36,
    double iconSize = 18,
    Color? iconColor,
    Color? accentColor,
    bool isDestructive = false,
    bool isDisabled = false,
  }) {
    return LiquidGlassButton(
      key: key,
      onTap: onTap,
      borderRadius: size / 2,
      padding: EdgeInsets.zero,
      width: size,
      height: size,
      accentColor: accentColor,
      isDestructive: isDestructive,
      isDisabled: isDisabled,
      child: Icon(
        icon,
        size: iconSize,
        color: iconColor ?? (isDestructive ? Colors.redAccent : Colors.white70),
      ),
    );
  }

  /// Factory for text buttons
  factory LiquidGlassButton.text({
    Key? key,
    required VoidCallback? onTap,
    required String text,
    IconData? icon,
    double borderRadius = 20,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    Color? accentColor,
    bool isDestructive = false,
    bool isDisabled = false,
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    final textColor = isDisabled 
        ? Colors.white38 
        : (isDestructive ? Colors.redAccent : Colors.white);
    
    return LiquidGlassButton(
      key: key,
      onTap: isDisabled ? null : onTap,
      borderRadius: borderRadius,
      padding: padding,
      accentColor: accentColor,
      isDestructive: isDestructive,
      isDisabled: isDisabled,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: fontSize,
                fontWeight: fontWeight,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Factory for primary action buttons with gradient
  factory LiquidGlassButton.primary({
    Key? key,
    required VoidCallback? onTap,
    required String text,
    IconData? icon,
    List<Color>? gradientColors,
    Color? borderColor,
    double borderRadius = 24,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    bool isDisabled = false,
    bool enableBlur = false,
    double fontSize = 14,
  }) {
    final colors = gradientColors ?? [
      const Color(0xFF4285F4),
      const Color(0xFF34A853),
    ];
    
    return LiquidGlassGradientButton(
      key: key,
      onTap: isDisabled ? null : onTap,
      text: text,
      icon: icon,
      gradientColors: colors,
      borderColor: borderColor,
      borderRadius: borderRadius,
      padding: padding,
      isDisabled: isDisabled,
      enableBlur: enableBlur,
      fontSize: fontSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? Colors.white;
    final borderCol = borderColor ?? (isDestructive 
        ? Colors.redAccent.withValues(alpha: 0.4)
        : accent.withValues(alpha: 0.15));
    final gradientColors = isDestructive
        ? [Colors.redAccent.withValues(alpha: 0.15), Colors.redAccent.withValues(alpha: 0.05)]
        : [accent.withValues(alpha: 0.12), accent.withValues(alpha: 0.06)];

    Widget button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDisabled 
                  ? [Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.02)]
                  : gradientColors,
            ),
            border: Border.all(
              color: isDisabled ? Colors.white.withValues(alpha: 0.08) : borderCol,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(child: child),
        ),
      ),
    );

    if (enableBlur) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: button,
        ),
      );
    }

    return button;
  }
}

/// Internal gradient button variant for primary actions
class LiquidGlassGradientButton extends LiquidGlassButton {
  final String? text;
  final IconData? icon;
  final List<Color> gradientColors;
  final double fontSize;
  final Widget? customChild;

  const LiquidGlassGradientButton({
    super.key,
    required super.onTap,
    this.text,
    this.icon,
    required this.gradientColors,
    super.borderColor,
    super.borderRadius = 24,
    super.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    super.isDisabled = false,
    super.enableBlur = false,
    this.fontSize = 14,
    this.customChild,
  }) : super(child: const SizedBox.shrink());

  @override
  Widget build(BuildContext context) {
    Widget button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: isDisabled
                ? LinearGradient(colors: [Colors.grey.shade700, Colors.grey.shade600])
                : LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            border: borderColor != null 
                ? Border.all(color: borderColor!, width: 1)
                : null,
            boxShadow: [
              if (!isDisabled)
                BoxShadow(
                  color: gradientColors.first.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: customChild ?? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
              ],
              if (text != null)
                Text(
                  text!,
                  style: GoogleFonts.inter(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (enableBlur) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: button,
        ),
      );
    }

    return button;
  }
}
