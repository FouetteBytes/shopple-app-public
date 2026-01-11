import 'package:flutter/material.dart';

/// Displays a number and animates subtly when the value changes.
class AnimatedDiffNumber extends StatefulWidget {
  final num value;
  final TextStyle? style;
  final Duration duration;
  final bool enableScale;
  final String? prefix;
  final String? suffix;
  const AnimatedDiffNumber({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 300),
    this.enableScale = true,
    this.prefix,
    this.suffix,
  });

  @override
  State<AnimatedDiffNumber> createState() => _AnimatedDiffNumberState();
}

class _AnimatedDiffNumberState extends State<AnimatedDiffNumber>
    with SingleTickerProviderStateMixin {
  late num _prevValue;
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _prevValue = widget.value;
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scale = Tween<double>(
      begin: 0.97,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  @override
  void didUpdateWidget(covariant AnimatedDiffNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _prevValue) {
      _prevValue = widget.value;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text =
        '${widget.prefix ?? ''}${_format(widget.value)}${widget.suffix ?? ''}';
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final child = Text(text, style: widget.style);
        return Opacity(
          opacity: _fade.value.clamp(0.6, 1.0),
          child: widget.enableScale
              ? Transform.scale(scale: _scale.value, child: child)
              : child,
        );
      },
    );
  }

  String _format(num v) {
    if (v is int) return v.toString();
    return v.toStringAsFixed(2);
  }
}
