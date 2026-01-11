import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shopple/services/media/pattern_background_service.dart';
import '../../values/values.dart';

/// Phase 4.2.A: Pattern Selection Grid
/// Copies the grid layout pattern from NewWorkSpace color selection
/// Uses existing Container styling with AppColors.surface
/// Applies existing border radius from AppColors theme
/// Maintains existing selection animation patterns

class PatternSelectionGrid extends StatefulWidget {
  final ProfileBackgroundOption? currentSelection;
  final Function(ProfileBackgroundOption) onPatternSelected;
  final List<ProfileBackgroundOption> patterns;

  const PatternSelectionGrid({
    super.key,
    this.currentSelection,
    required this.onPatternSelected,
    required this.patterns,
  });

  @override
  State<PatternSelectionGrid> createState() => _PatternSelectionGridState();
}

class _PatternSelectionGridState extends State<PatternSelectionGrid>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimationLimiter(
      child: Container(
        width: screenWidth - 40, // Safe width - copying NewWorkSpace pattern
        padding: EdgeInsets.only(top: 15.0),
        child: Column(
          children: [
            // Using existing grid pattern from NewWorkSpace
            _buildPatternRows(),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternRows() {
    List<Widget> rows = [];
    final patterns = widget.patterns;

    // Create rows of 5 patterns each (matching NewWorkSpace layout)
    for (int i = 0; i < patterns.length; i += 5) {
      final rowPatterns = patterns.skip(i).take(5).toList();

      rows.add(
        AnimationConfiguration.staggeredList(
          position: i ~/ 5,
          duration: const Duration(milliseconds: 375),
          child: SlideAnimation(
            verticalOffset: 30.0,
            child: FadeInAnimation(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: rowPatterns
                    .map((pattern) => _buildPatternBall(pattern))
                    .toList(),
              ),
            ),
          ),
        ),
      );

      if (i + 5 < patterns.length) {
        rows.add(SizedBox(height: 10)); // Match existing spacing
      }
    }

    return Column(children: rows);
  }

  Widget _buildPatternBall(ProfileBackgroundOption pattern) {
    final screenWidth = MediaQuery.of(context).size.width;
    var size =
        ((screenWidth - 46) / 5) - 5; // Same calculation as GradientColorBall
    size = size.clamp(30.0, 60.0); // Safety check

    final isSelected = widget.currentSelection?.id == pattern.id;

    return InkWell(
      onTap: () => widget.onPatternSelected(pattern),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            15.0,
          ), // Same as GradientColorBall
          border: isSelected
              ? Border.all(
                  color: HexColor.fromHex("266FFE"),
                  width: 2,
                ) // Same selection style
              : Border.all(width: 0, color: HexColor.fromHex("181A1F")),
        ),
        child: Center(
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(shape: BoxShape.circle),
            child: ClipOval(child: _buildPatternPreview(pattern)),
          ),
        ),
      ),
    );
  }

  Widget _buildPatternPreview(ProfileBackgroundOption pattern) {
    switch (pattern.type) {
      case BackgroundType.solid:
      case BackgroundType.gradient:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: pattern.colors.isNotEmpty
                  ? pattern.colors
                  : AppColors.ballColors[0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
        );

      case BackgroundType.pattern:
        return ClipOval(
          child: PatternBackgroundService.createPatternWidget(
            option: pattern,
            width: 50,
            height: 50,
          ),
        );

      case BackgroundType.animated:
        // Show static preview for animated patterns
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: pattern.colors.isNotEmpty
                  ? pattern.colors
                  : AppColors.ballColors[0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.play_circle_filled,
            color: const Color(0xFFFFFFFF).withValues(alpha: 0.8),
            size: 12,
          ),
        );

      // No default needed; enum cases are covered above
    }
  }
}
