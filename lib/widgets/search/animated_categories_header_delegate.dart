import 'package:flutter/material.dart';

class AnimatedCategoriesHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minExtentHeight;
  final double maxExtentHeight;
  final Widget Function(BuildContext, double, bool) builder;
  final int rebuildToken; // triggers rebuild when state changes outside scroll
  final bool forceCollapsed; // when true, header reports minExtent as its max

  AnimatedCategoriesHeaderDelegate({
    required this.minExtentHeight,
    required this.maxExtentHeight,
    required this.rebuildToken,
    required this.forceCollapsed,
    required this.builder,
  });

  @override
  double get minExtent => minExtentHeight;

  @override
  double get maxExtent => forceCollapsed ? minExtentHeight : maxExtentHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return builder(context, shrinkOffset, overlapsContent);
  }

  @override
  bool shouldRebuild(covariant AnimatedCategoriesHeaderDelegate oldDelegate) {
    return oldDelegate.minExtentHeight != minExtentHeight ||
        oldDelegate.maxExtentHeight != maxExtentHeight ||
        oldDelegate.builder != builder ||
        oldDelegate.rebuildToken != rebuildToken ||
        oldDelegate.forceCollapsed != forceCollapsed;
  }
}
