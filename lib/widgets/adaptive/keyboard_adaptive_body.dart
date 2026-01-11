import 'package:flutter/material.dart';

/// KeyboardAdaptiveBody
/// Wrap scrollable form/content so it never overflows when keyboard appears.
/// - Adds bottom padding equal to current viewInsets.bottom + extra.
/// - Optionally shrinks large vertical gaps when keyboard is open.
class KeyboardAdaptiveBody extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool shrinkGaps;
  final double extraBottom;

  /// When true: no scrolling when keyboard is closed; a scroll view is only
  /// introduced while the keyboard is open (to allow reaching obscured fields).
  final bool scrollWhenKeyboardOnly;
  const KeyboardAdaptiveBody({
    super.key,
    required this.child,
    this.padding,
    this.shrinkGaps = true,
    this.extraBottom = 16,
    this.scrollWhenKeyboardOnly = false,
  });
  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;
    final kb = insets.bottom;
    final bool keyboardOpen = kb > 0;
    final EdgeInsets basePad =
        (padding ?? EdgeInsets.zero) as EdgeInsets? ?? EdgeInsets.zero;
    final content = _GapShrinkScope(
      shrink: shrinkGaps && keyboardOpen,
      child: child,
    );
    final body = scrollWhenKeyboardOnly
        ? (keyboardOpen
              ? SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: content,
                )
              : content)
        : SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOut,
              child: content,
            ),
          );
    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: basePad.copyWith(bottom: (basePad.bottom) + kb + extraBottom),
      child: body,
    );
  }
}

/// Inherit shrink flag to custom gap widgets if we add any later.
class _GapShrinkScope extends InheritedWidget {
  final bool shrink;
  const _GapShrinkScope({required this.shrink, required super.child});
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_GapShrinkScope>()?.shrink ??
      false;
  @override
  bool updateShouldNotify(covariant _GapShrinkScope oldWidget) =>
      shrink != oldWidget.shrink;
}

/// Utility spacer that auto-shrinks when keyboard is open.
class KbGap extends StatelessWidget {
  final double size;
  final double minSize;
  const KbGap(this.size, {super.key, this.minSize = 8});
  @override
  Widget build(BuildContext context) {
    final shrink = _GapShrinkScope.of(context);
    final target = shrink ? minSize : size;
    return SizedBox(height: target);
  }
}
