import 'package:flutter/material.dart';
import '../../values/values.dart';
import 'package:flutter_shapes/flutter_shapes.dart';

class BackgroundHexagon extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = AppColors.surface;
    Shapes shapes = Shapes(
      canvas: canvas,
      radius: 50,
      paint: paint,
      center: Offset.zero,
      angle: 0,
    );

    shapes.drawType(ShapeType.Hexagon); // enum
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // TODO: implement shouldRepaint
    return false;
  }
}
