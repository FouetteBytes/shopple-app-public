import 'package:flutter/material.dart';
import 'package:shopple/widgets/animations/rotation_3d.dart';
import 'package:shopple/data/onboarding_data.dart';
import 'package:shopple/widgets/onboarding/onboarding_card_renderer.dart';

class OnboardingParallaxCards extends StatefulWidget {
  final List<OnboardingSlide> slides;
  final Function(OnboardingSlide) onSlideChange;

  const OnboardingParallaxCards({
    super.key,
    required this.slides,
    required this.onSlideChange,
  });

  @override
  State<OnboardingParallaxCards> createState() =>
      _OnboardingParallaxCardsState();
}

class _OnboardingParallaxCardsState extends State<OnboardingParallaxCards>
    with SingleTickerProviderStateMixin {
  // Rotation (in degrees) applied across all cards based on drag offset
  static const double _maxRotation = 20;

  // Sizing
  double _cardWidth = 200;
  double _cardHeight = 320;

  // Scroll + gesture derived state (normalized -1..1)
  double _normalizedOffset = 0;
  double _prevScrollPx = 0;
  bool _isScrolling = false;

  // Current reported slide index
  int _currentSlideLogicalIndex = 0;

  // Controller for PageView (lazy created once we know constraints)
  PageController? _pageController;

  // Tween + animation to smoothly snap offset back to zero after user releases
  late final AnimationController _tweenController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  final Tween<double> _tween = Tween<double>(begin: 0, end: 0);
  late final Animation<double> _tweenAnim = CurvedAnimation(
    parent: _tweenController,
    curve: Curves.elasticOut,
  ).drive(_tween);

  // ValueNotifier to avoid rebuilding ancestor widgets every frame; only cards repaint.
  final ValueNotifier<double> _offsetNotifier = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _tweenAnim.addListener(() => _setOffset(_tweenAnim.value));

    // Precache the three-layer parallax images to reduce first-scroll jank.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (var slide in widget.slides) {
        // Precache all three layers for each city
        precacheImage(
          AssetImage('assets/${slide.name}/${slide.name}-Back.png'),
          context,
        ).catchError((_) {});
        precacheImage(
          AssetImage('assets/${slide.name}/${slide.name}-Middle.png'),
          context,
        ).catchError((_) {});
        precacheImage(
          AssetImage('assets/${slide.name}/${slide.name}-Front.png'),
          context,
        ).catchError((_) {});
      }
    });
  }

  @override
  void dispose() {
    _tweenController.dispose();
    _pageController?.dispose();
    _offsetNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Derive sizes from available height
        final h = constraints.maxHeight;
        _cardHeight = h.clamp(300.0, 400.0);
        _cardWidth = _cardHeight * 0.78;

        _pageController ??= PageController(
          // Start somewhere in the middle of a large range to simulate infinite scroll feeling
          initialPage: widget.slides.length * 50,
          viewportFraction: (_cardWidth / constraints.maxWidth).clamp(
            0.32,
            0.9,
          ),
        );

        final list = SizedBox(
          height: _cardHeight,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            itemCount:
                widget.slides.length *
                100, // large multiple for pseudo-infinite effect
            itemBuilder: (context, index) => _buildCard(index),
          ),
        );

        return Listener(
          onPointerUp: _handlePointerUp,
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: list,
          ),
        );
      },
    );
  }

  Widget _buildCard(int index) {
    final slide = widget.slides[index % widget.slides.length];
    return RepaintBoundary(
      child: ValueListenableBuilder<double>(
        valueListenable: _offsetNotifier,
        builder: (context, offset, _) {
          return Rotation3d(
            rotationY: offset * _maxRotation,
            child: OnboardingCardRenderer(
              offset,
              slide: slide,
              cardWidth: _cardWidth,
              cardHeight: _cardHeight - 40,
            ),
          );
        },
      ),
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _isScrolling = true;
      _prevScrollPx = notification.metrics.pixels;
      _tweenController.stop();
    } else if (notification is ScrollUpdateNotification) {
      final metrics = notification.metrics;
      final dx = metrics.pixels - _prevScrollPx;
      _prevScrollPx = metrics.pixels;

      // Translate pixel delta into a small normalized rotation offset
      const scrollFactor = 0.004; // tuning knob
      final newOffset = (_normalizedOffset + dx * scrollFactor).clamp(
        -1.0,
        1.0,
      );
      _setOffset(newOffset);

      // Determine current logical slide
      final rawPage = metrics.pixels / metrics.viewportDimension;
      final logicalIndex = rawPage.round() % widget.slides.length;
      if (logicalIndex != _currentSlideLogicalIndex) {
        _currentSlideLogicalIndex = logicalIndex;
        widget.onSlideChange(widget.slides[logicalIndex]);
      }
    } else if (notification is ScrollEndNotification) {
      // Natural scroll end (fling) may still produce an EndNotification, let pointer up also handle.
      _isScrolling = false;
      _startOffsetSnapBack();
    }
    return true;
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_isScrolling) {
      _isScrolling = false;
      _startOffsetSnapBack();
    }
  }

  void _setOffset(double value) {
    _normalizedOffset = value;
    _offsetNotifier.value = value; // notify listeners (cards repaint only)
  }

  void _startOffsetSnapBack() {
    _tween
      ..begin = _normalizedOffset
      ..end = 0;
    _tweenController
      ..reset()
      ..forward();
  }
}
