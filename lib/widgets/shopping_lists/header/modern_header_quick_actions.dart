import 'package:flutter/material.dart';

/// Horizontally scrollable quick action row that keeps buttons compact.
class ModernHeaderQuickActions extends StatelessWidget {
  final List<Widget> children;

  const ModernHeaderQuickActions({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            for (int i = 0; i < children.length; i++)
              Padding(
                padding: EdgeInsets.only(
                  right: i == children.length - 1 ? 0 : 8,
                ),
                child: children[i],
              ),
          ],
        ),
      ),
    );
  }
}
