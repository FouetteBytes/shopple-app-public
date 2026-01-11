import 'dart:ui';
import 'package:flutter/material.dart';
import 'splash_painters.dart';

const _initialTrackHeadDiameter = 102.0;
const _finalTrackHeadDiameter = 132.0;

class TrackClipper extends CustomClipper<Path> {
  TrackClipper({required this.progress, required this.expansion})
    : super(reclip: Listenable.merge([progress, expansion]));

  final Animation<double> progress;
  final Animation<double> expansion;

  @override
  Path getClip(Size size) {
    final track = Track.fromScreenRect(
      screenRect: Offset.zero & size,
      progress: progress.value,
      expansion: expansion.value,
    );

    return track.path;
  }

  @override
  bool shouldReclip(TrackClipper oldClipper) {
    return oldClipper.progress != progress || oldClipper.expansion != expansion;
  }
}

class IconPositionDelegate extends SingleChildLayoutDelegate {
  IconPositionDelegate({required this.progress, required this.expansion})
    : super(relayout: Listenable.merge([progress, expansion]));

  final Animation<double> progress;
  final Animation<double> expansion;

  @override
  Size getSize(BoxConstraints constraints) => constraints.biggest;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final diameter = lerpDouble(
      _initialTrackHeadDiameter,
      _finalTrackHeadDiameter,
      expansion.value,
    );

    return constraints.enforce(
      BoxConstraints.tightFor(width: diameter, height: diameter),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final track = Track.fromScreenRect(
      screenRect: Offset.zero & size,
      progress: progress.value,
      expansion: 0,
    );

    final radius = childSize.width / 2;
    return track.trackHeadCenter.translate(-radius, -radius);
  }

  @override
  bool shouldRelayout(IconPositionDelegate oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.expansion != expansion;
  }
}
