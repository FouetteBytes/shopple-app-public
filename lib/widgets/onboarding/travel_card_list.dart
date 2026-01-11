import 'package:flutter/material.dart';
import 'package:shopple/widgets/animations/rotation_3d.dart';
import 'package:shopple/data/city_data.dart';
import 'package:shopple/widgets/onboarding/travel_card_renderer.dart';

class TravelCardList extends StatefulWidget {
  final List<City> cities;
  final Function onCityChange;

  const TravelCardList({
    super.key,
    required this.cities,
    required this.onCityChange,
  });

  @override
  TravelCardListState createState() => TravelCardListState();
}

class TravelCardListState extends State<TravelCardList>
    with SingleTickerProviderStateMixin {
  final double _maxRotation = 20;

  PageController? _pageController;

  double _cardWidth = 160;
  double _cardHeight = 200;
  double _normalizedOffset = 0;
  double _prevScrollX = 0;
  bool _isScrolling = false;
  //int _focusedIndex = 0;

  //Create Controller, which starts/stops the tween, and rebuilds this widget while it's running
  late final AnimationController _tweenController = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 1000),
  );
  //Create Tween, which defines our begin + end values
  final Tween<double> _tween = Tween<double>(begin: -1, end: 0);
  //Create Animation, which allows us to access the current tween value and the onUpdate() callback.
  late final Animation<double> _tweenAnim = _tween.animate(
    CurvedAnimation(parent: _tweenController, curve: Curves.elasticOut),
  );
  @override
  void initState() {
    //Set our offset each time the tween updates
    _tweenAnim.addListener(() => _setOffset(_tweenAnim.value));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder so the cards can size relative to the actual space provided by the parent
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = MediaQuery.of(context).size;
        // Height available in the top onboarding section
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : screenSize.height * .5;

        // Fill almost entire available height (leave tiny breathing room)
        _cardHeight = (availableHeight - 4).clamp(320.0, availableHeight);
        // Slightly wider ratio to better occupy horizontal space but keep peek of neighbors
        _cardWidth = (_cardHeight * .82).clamp(
          260.0,
          constraints.maxWidth * 0.9,
        );

        // Persist controller to maintain scroll position across rebuilds
        _pageController ??= PageController(
          initialPage:
              10000, // large number to allow seemingly infinite bi-directional scrolling
          viewportFraction: (_cardWidth / screenSize.width).clamp(0.55, 0.95),
        );

        // PageView holding the travel cards
        final pageView = SizedBox(
          height: _cardHeight,
          child: PageView.builder(
            physics: const BouncingScrollPhysics(),
            controller: _pageController,
            // No itemCount -> infinite pages
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, i) => _buildRotatedTravelCard(i),
          ),
        );

        // Wrap in alignment + listeners (listeners must be outside the Align to capture pointer events)
        return Listener(
          onPointerUp: _handlePointerUp,
          child: NotificationListener(
            onNotification: _handleScrollNotifications,
            child: Align(
              alignment: Alignment
                  .center, // Center vertically within the allotted region
              child: pageView,
            ),
          ),
        );
      },
    );
  }

  // Build card with 3D rotation effect
  Widget _buildRotatedTravelCard(int itemIndex) {
    return Rotation3d(
      rotationY: _normalizedOffset * _maxRotation,
      child: RepaintBoundary(
        child: TravelCardRenderer(
          _normalizedOffset,
          city: widget.cities[itemIndex % widget.cities.length],
          cardWidth: _cardWidth,
          cardHeight: _cardHeight - 50,
        ),
      ),
    );
  }

  // Process scroll notifications to update offset and state
  bool _handleScrollNotifications(Notification notification) {
    if (notification is ScrollUpdateNotification) {
      if (_isScrolling) {
        double dx = notification.metrics.pixels - _prevScrollX;
        double scrollFactor = .01;
        double newOffset = (_normalizedOffset + dx * scrollFactor);
        _setOffset(newOffset.clamp(-1.0, 1.0));
      }
      _prevScrollX = notification.metrics.pixels;
      final currentPage = _pageController?.page?.round();
      if (currentPage != null) {
        widget.onCityChange(
          widget.cities.elementAt(currentPage % widget.cities.length),
        );
      }
    } else if (notification is ScrollStartNotification) {
      _isScrolling = true;
      _prevScrollX = notification.metrics.pixels;
      _tweenController.stop();
    }
    return true;
  }

  // Handle scroll end when pointer released
  void _handlePointerUp(PointerUpEvent event) {
    if (_isScrolling) {
      _isScrolling = false;
      _startOffsetTweenToZero();
    }
  }

  // Update offset and trigger rebuild
  void _setOffset(double value) {
    if ((value - _normalizedOffset).abs() < 0.01) {
      return; // throttle tiny changes
    }
    setState(() => _normalizedOffset = value);
  }

  // Animate offset back to zero
  void _startOffsetTweenToZero() {
    _tween.begin = _normalizedOffset;
    _tweenController.reset();
    _tween.end = 0;
    _tweenController.forward();
  }
}
