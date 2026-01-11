import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shopple/values/values.dart';

const _initialTrackWidth = 112.0;

class TrackPainter extends CustomPainter {
  TrackPainter({required this.progress}) : super(repaint: progress);

  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final track = Track.fromScreenRect(
      screenRect: Offset.zero & size,
      progress: progress.value,
      expansion: 0,
    );

    canvas.drawPath(
      track.path,
      Paint()..color = AppColors.darkGreenBackground.withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(TrackPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class AppIconCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final center = Offset(side * 0.5, side * 0.5);
    final radius = side * 0.5;

    // Create a circular clip for the background image
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );

    // Try to load and draw shopple_background.png as the circle background
    try {
      // images in CustomPainter without pre-loading them
      final backgroundPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = AppColors.primaryAccentColor;

      canvas.drawCircle(center, radius, backgroundPaint);
    } catch (e) {
      // Fallback to accent color if asset loading fails
      final fallbackPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = AppColors.primaryAccentColor;

      canvas.drawCircle(center, radius, fallbackPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class Track {
  const Track._({required this.path, required this.trackHeadCenter});

  factory Track.fromScreenRect({
    required Rect screenRect,
    required double progress,
    required double expansion,
  }) {
    final screenBottomCenter = screenRect.bottomCenter;

    final startY = screenRect.height + _initialTrackWidth / 2;
    const endY = -_initialTrackWidth;

    final dy = math.max(lerpDouble(startY, endY, progress)!, endY);

    final trackWidth =
        _initialTrackWidth +
        (screenRect.width - _initialTrackWidth) * expansion;
    final halfTrackWidth = trackWidth / 2;

    final trackTopLeft = Offset(screenBottomCenter.dx - halfTrackWidth, dy);
    final trackBottomRight = Offset(
      screenBottomCenter.dx + halfTrackWidth,
      startY,
    );

    final trackRect = Rect.fromPoints(trackTopLeft, trackBottomRight);

    final path = Path()
      ..addRect(trackRect)
      ..moveTo(trackRect.topLeft.dx, trackRect.topLeft.dy)
      ..arcToPoint(
        trackRect.topRight,
        radius: Radius.elliptical(trackWidth / 2, trackWidth / 2),
      )
      ..close();

    return Track._(path: path, trackHeadCenter: trackRect.topCenter);
  }

  final Path path;
  final Offset trackHeadCenter;
}
