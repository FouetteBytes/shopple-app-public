import 'package:flutter/material.dart';
import 'package:shopple/values/values.dart';
import 'package:get/get.dart';

/// iOS-style slidable button that allows switching between different icons
/// User can slide left/right to select an icon, then tap to navigate
class SlidableIconButton extends StatefulWidget {
  final List<SlidableIconItem> items;
  final double size;

  const SlidableIconButton({super.key, required this.items, this.size = 56});

  @override
  State<SlidableIconButton> createState() => _SlidableIconButtonState();
}

class _SlidableIconButtonState extends State<SlidableIconButton>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  double _dragStartX = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    _dragStartX = details.localPosition.dx;
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    final delta = details.localPosition.dx - _dragStartX;
    if (delta.abs() > 20) {
      // Threshold for switching
      setState(() {
        if (delta > 0) {
          // Swipe right - go to previous
          _currentIndex = (_currentIndex - 1) % widget.items.length;
          if (_currentIndex < 0) _currentIndex = widget.items.length - 1;
        } else {
          // Swipe left - go to next
          _currentIndex = (_currentIndex + 1) % widget.items.length;
        }
      });
      _dragStartX = details.localPosition.dx;
      _animationController.forward().then(
        (_) => _animationController.reverse(),
      );
    }
  }

  void _handleTap() {
    final item = widget.items[_currentIndex];
    _animationController.forward().then((_) {
      _animationController.reverse();
      if (item.onTap != null) {
        item.onTap!();
      } else if (item.page != null) {
        Get.to(() => item.page!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = widget.items[_currentIndex];

    return GestureDetector(
      onTap: _handleTap,
      onHorizontalDragStart: _handleHorizontalDragStart,
      onHorizontalDragUpdate: _handleHorizontalDragUpdate,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.15),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(widget.size / 2),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Main Icon
                  Icon(
                    currentItem.icon,
                    color: AppColors.primaryText,
                    size: widget.size * 0.45,
                  ),
                  // Badge indicator
                  if (currentItem.badgeCount != null &&
                      currentItem.badgeCount! > 0)
                    Positioned(
                      top: widget.size * 0.15,
                      right: widget.size * 0.15,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: HexColor.fromHex("FF6B6B"),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.background,
                            width: 1.5,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          currentItem.badgeCount! > 99
                              ? '99+'
                              : currentItem.badgeCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  // Slide indicator dots at bottom
                  if (widget.items.length > 1)
                    Positioned(
                      bottom: widget.size * 0.12,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          widget.items.length,
                          (index) => Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: _currentIndex == index
                                  ? AppColors.primaryGreen
                                  : Colors.white.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Item configuration for slidable icon button
class SlidableIconItem {
  final IconData icon;
  final Widget? page;
  final VoidCallback? onTap;
  final int? badgeCount;

  const SlidableIconItem({
    required this.icon,
    this.page,
    this.onTap,
    this.badgeCount,
  });
}
