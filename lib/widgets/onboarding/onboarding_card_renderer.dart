import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/data/onboarding_data.dart';
import 'package:shopple/utils/app_logger.dart';

class OnboardingCardRenderer extends StatelessWidget {
  final double offset;
  final double cardWidth;
  final double cardHeight;
  final OnboardingSlide slide;

  const OnboardingCardRenderer(
    this.offset, {
    super.key,
    this.cardWidth = 250,
    required this.slide,
    required this.cardHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: cardWidth,
      margin: EdgeInsets.only(top: 8),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          /// Card background color & decoration
          Container(
            margin: EdgeInsets.only(top: 30, left: 12, right: 12, bottom: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  slide.color.withValues(alpha: 0.8),
                  slide.color.withValues(alpha: 0.6),
                  slide.color.withValues(alpha: 0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: slide.color.withValues(alpha: 0.3),
                  blurRadius: 8 + 4 * offset.abs(),
                  offset: Offset(0, 4 + 2 * offset.abs()),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15 + 6 * offset.abs(),
                  offset: Offset(0, 8 + 4 * offset.abs()),
                ),
              ],
            ),
          ),

          /// Slide image stack with parallax effect
          Positioned(top: -15, child: _buildSlideImageStack()),

          /// Slide information
          _buildSlideInfo(),
        ],
      ),
    );
  }

  Widget _buildSlideImageStack() {
    Widget offsetLayer(
      String path,
      double width,
      double maxOffset,
      double globalOffset,
    ) {
      double cardPadding = 24;
      double layerWidth = cardWidth - cardPadding;
      return Positioned(
        left:
            ((layerWidth * .5) - (width / 2) - offset * maxOffset) +
            globalOffset,
        bottom: cardHeight * .45,
        child: Image.asset(
          path,
          width: width,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback if specific slide images don't exist
            AppLogger.w(
              'OnboardingCardRenderer: Error loading image: $path - $error',
            );
            return _buildFallbackIcon(width);
          },
        ),
      );
    }

    double maxParallax = 30;
    double globalOffset = offset * maxParallax * 2;
    double cardPadding = 28;
    double containerWidth = cardWidth - cardPadding;

    return SizedBox(
      height: cardHeight,
      width: containerWidth,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none, // Allow images to overflow if needed
        children: <Widget>[
          // Three-layer parallax effect matching the original travel cards
          offsetLayer(
            "assets/${slide.name}/${slide.name}-Back.png",
            containerWidth * .8,
            maxParallax * .1,
            globalOffset,
          ),
          offsetLayer(
            "assets/${slide.name}/${slide.name}-Middle.png",
            containerWidth * .9,
            maxParallax * .6,
            globalOffset,
          ),
          offsetLayer(
            "assets/${slide.name}/${slide.name}-Front.png",
            containerWidth * .9,
            maxParallax,
            globalOffset,
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackIcon(double width) {
    IconData icon;
    switch (slide.name) {
      case 'Pisa':
        icon = Icons.location_city;
        break;
      case 'Budapest':
        icon = Icons.castle;
        break;
      case 'London':
        icon = Icons.location_city;
        break;
      default:
        icon = Icons.star;
    }

    return Container(
      width: width,
      height: width,
      decoration: BoxDecoration(
        color: slide.color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: slide.color, size: width * 0.4),
    );
  }

  Widget _buildSlideInfo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        // The sized box mock the space of the slide image
        SizedBox(width: double.infinity, height: cardHeight * .57),

        /// Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            slide.title,
            style: GoogleFonts.lato(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        SizedBox(height: 8),

        /// Description
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            slide.description,
            style: GoogleFonts.lato(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        Expanded(child: SizedBox()),

        /// Bottom decorative element
        Container(
          width: 40,
          height: 4,
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
