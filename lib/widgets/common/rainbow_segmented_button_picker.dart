import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../values/values.dart';

/// Tab data model for the rainbow segmented button picker
class RainbowSegmentedTab {
  final String text;
  final Widget icon;
  final String? tooltip;

  const RainbowSegmentedTab({
    required this.text,
    required this.icon,
    this.tooltip,
  });
}

/// Reusable rainbow segmented button picker widget with Google AI rainbow gradient
/// Similar to SegmentedButtonPicker but with rainbow gradient instead of solid color
class RainbowSegmentedButtonPicker extends StatelessWidget {
  final TabController controller;
  final List<RainbowSegmentedTab> tabs;
  final double height;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final BorderRadius? indicatorBorderRadius;
  final Color? backgroundColor;
  final Color? labelColor;
  final Color? unselectedLabelColor;
  final List<Color>? gradientColors;
  final VoidCallback? onTap;

  /// Google AI rainbow gradient colors (default)
  static const List<Color> defaultRainbowGradient = [
    Color(0xFF4285F4), // Google Blue
    Color(0xFF34A853), // Google Green
    Color(0xFFFBBC04), // Google Yellow
    Color(0xFFEA4335), // Google Red
    Color(0xFF9C27B0), // Purple
    Color(0xFF00BCD4), // Cyan
  ];

  const RainbowSegmentedButtonPicker({
    super.key,
    required this.controller,
    required this.tabs,
    this.height = 60,
    this.padding,
    this.borderRadius,
    this.indicatorBorderRadius,
    this.backgroundColor,
    this.labelColor,
    this.unselectedLabelColor,
    this.gradientColors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(15),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors ?? defaultRainbowGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: indicatorBorderRadius ?? BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: padding ?? EdgeInsets.all(4),
        labelColor: labelColor ?? Colors.white,
        unselectedLabelColor: unselectedLabelColor ?? Colors.grey[400],
        labelStyle: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.lato(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        dividerColor: Colors.transparent,
        onTap: onTap != null ? (_) => onTap!() : null,
        tabs: tabs.map((tab) => Tab(text: tab.text, icon: tab.icon)).toList(),
      ),
    );
  }
}

/// Helper class to create standardized tabs for RainbowSegmentedButtonPicker
class RainbowSegmentedTabFactory {
  /// Creates a simple tab with text and icon
  static RainbowSegmentedTab simple({
    required String text,
    required IconData icon,
    double iconSize = 20,
    String? tooltip,
  }) {
    return RainbowSegmentedTab(
      text: text,
      icon: Icon(icon, size: iconSize),
      tooltip: tooltip,
    );
  }

  /// Creates a tab with a badge/notification count
  static RainbowSegmentedTab withBadge({
    required String text,
    required IconData icon,
    required Stream<int> countStream,
    double iconSize = 20,
    String? tooltip,
  }) {
    return RainbowSegmentedTab(
      text: text,
      icon: StreamBuilder<int>(
        stream: countStream,
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;
          return Stack(
            children: [
              Icon(icon, size: iconSize),
              if (count > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      count.toString(),
                      style: TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      tooltip: tooltip,
    );
  }
}
