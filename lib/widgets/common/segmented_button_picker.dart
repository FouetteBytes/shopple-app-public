import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../values/values.dart';

/// Tab data model for the segmented button picker
class SegmentedTab {
  final String text;
  final Widget icon;
  final String? tooltip;

  const SegmentedTab({required this.text, required this.icon, this.tooltip});
}

/// Reusable segmented button picker widget with rounded styling
/// Extracted from FriendsScreen._buildTabBar for consistency across screens
class SegmentedButtonPicker extends StatelessWidget {
  final TabController controller;
  final List<SegmentedTab> tabs;
  final double height;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final BorderRadius? indicatorBorderRadius;
  final Color? backgroundColor;
  final Color? indicatorColor;
  final Color? labelColor;
  final Color? unselectedLabelColor;

  const SegmentedButtonPicker({
    super.key,
    required this.controller,
    required this.tabs,
    this.height = 60,
    this.padding,
    this.borderRadius,
    this.indicatorBorderRadius,
    this.backgroundColor,
    this.indicatorColor,
    this.labelColor,
    this.unselectedLabelColor,
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
          color: indicatorColor ?? AppColors.primaryAccentColor,
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
        tabs: tabs.map((tab) => Tab(text: tab.text, icon: tab.icon)).toList(),
      ),
    );
  }
}

/// Helper class to create standardized tabs for SegmentedButtonPicker
class SegmentedTabFactory {
  /// Creates a simple tab with text and icon
  static SegmentedTab simple({
    required String text,
    required IconData icon,
    double iconSize = 20,
    String? tooltip,
  }) {
    return SegmentedTab(
      text: text,
      icon: Icon(icon, size: iconSize),
      tooltip: tooltip,
    );
  }

  /// Creates a tab with a badge/notification count
  static SegmentedTab withBadge({
    required String text,
    required IconData icon,
    required Stream<int> countStream,
    double iconSize = 20,
    String? tooltip,
  }) {
    return SegmentedTab(
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
