import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A widget that applies 3D rotation transformations to its child
class Rotation3d extends StatelessWidget {
  final double rotationX;
  final double rotationY;
  final double rotationZ;
  final Widget child;

  const Rotation3d({
    super.key,
    this.rotationX = 0,
    this.rotationY = 0,
    this.rotationZ = 0,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // Add perspective
        ..rotateX(rotationX * math.pi / 180)
        ..rotateY(rotationY * math.pi / 180)
        ..rotateZ(rotationZ * math.pi / 180),
      child: child,
    );
  }
}
