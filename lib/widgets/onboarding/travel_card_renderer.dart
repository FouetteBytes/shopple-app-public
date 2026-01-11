import 'package:flutter/material.dart';
import 'package:shopple/data/city_data.dart';
import 'package:shopple/values/parallax_styles.dart';
import 'package:shopple/widgets/common/liquid_glass_button.dart';

class TravelCardRenderer extends StatelessWidget {
  final double offset;
  final double cardWidth;
  final double cardHeight;
  final City city;

  const TravelCardRenderer(
    this.offset, {
    super.key,
    this.cardWidth = 250,
    required this.city,
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
            // Tighter margins to let larger card fill space
            margin: EdgeInsets.only(top: 32, left: 10, right: 10, bottom: 10),
            decoration: BoxDecoration(
              color: city.color,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 4 * offset.abs()),
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10 + 6 * offset.abs(),
                ),
              ],
            ),
          ),

          /// City image, positioned to better fill the card
          Positioned(top: 10, child: _buildCityImageStack()),

          /// City information
          _buildCityInfo(),
        ],
      ),
    );
  }

  Widget _buildCityImageStack() {
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
        // Move layers a bit lower to visually center within the card
        bottom: cardHeight * .39,
        child: Image.asset(path, width: width),
      );
    }

    double maxParallax = 36; // slightly larger parallax for bigger image
    double globalOffset = offset * maxParallax * 2;
    double cardPadding = 28;
    double containerWidth = cardWidth - cardPadding;
    return SizedBox(
      height: cardHeight,
      width: containerWidth,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          offsetLayer(
            "assets/${city.name}/${city.name}-Back.png",
            containerWidth * .88,
            maxParallax * .1,
            globalOffset,
          ),
          offsetLayer(
            "assets/${city.name}/${city.name}-Middle.png",
            containerWidth * .995,
            maxParallax * .6,
            globalOffset,
          ),
          offsetLayer(
            "assets/${city.name}/${city.name}-Front.png",
            containerWidth * 1.05,
            maxParallax,
            globalOffset,
          ),
        ],
      ),
    );
  }

  Widget _buildCityInfo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        // The sized box mock the space of the city image
        Spacer(),

        /// Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            city.title,
            style: ParallaxStyles.cardTitle,
            textAlign: TextAlign.center,
          ),
        ),

        SizedBox(height: 8),

        /// Desc
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Text(
            city.description,
            style: ParallaxStyles.cardSubtitle,
            textAlign: TextAlign.center,
          ),
        ),

        SizedBox(height: 12),

        /// Bottom btn
        LiquidGlassButton.text(
          onTap: null,
          text: 'Learn More'.toUpperCase(),
          isDisabled: true,
        ),
        SizedBox(height: 16),
      ],
    );
  }
}
