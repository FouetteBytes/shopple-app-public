import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:rive/rive.dart';

/// A tiny helper to optionally render a Lottie (.json) or Rive (.riv) animation.
/// If the asset is missing or fails to load, it renders a sized placeholder.
class OptionalAnimation extends StatelessWidget {
  final String asset;
  final double width;
  final double height;
  final BoxFit fit;
  final bool loop;

  const OptionalAnimation({
    super.key,
    required this.asset,
    this.width = 160,
    this.height = 160,
    this.fit = BoxFit.contain,
    this.loop = true,
  });

  bool get _isLottie => asset.toLowerCase().endsWith('.json');
  bool get _isRive => asset.toLowerCase().endsWith('.riv');

  @override
  Widget build(BuildContext context) {
    if (_isLottie) {
      return SizedBox(
        width: width,
        height: height,
        child: Lottie.asset(
          asset,
          fit: fit,
          repeat: loop,
          errorBuilder: (context, error, stack) => _placeholder(),
        ),
      );
    }

    if (_isRive) {
      // Verify asset exists to avoid runtime errors
      return FutureBuilder<bool>(
        future: _assetExists(asset),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return _placeholder();
          }
          if (snap.data == true) {
            return SizedBox(
              width: width,
              height: height,
              child: RiveAnimation.asset(asset, fit: fit),
            );
          }
          return _placeholder();
        },
      );
    }

    return _placeholder();
  }

  Future<bool> _assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  Widget _placeholder() =>
      SizedBox(width: width, height: height, child: const SizedBox.shrink());
}
