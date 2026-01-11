import 'package:flutter/material.dart';
import '../../values/values.dart';

import 'dart:math' as math;

class BottomNavigationItem extends StatelessWidget {
  final IconData icon;
  final int itemIndex;
  final ValueNotifier<int> notifier;

  // Google AI rainbow gradient colors for AI button (index 5)
  static const List<Color> _aiRainbowGradient = [
    Color(0xFF4285F4), // Google Blue
    Color(0xFF34A853), // Google Green
    Color(0xFFFBBC04), // Google Yellow
    Color(0xFFEA4335), // Google Red
    Color(0xFF9C27B0), // Purple
    Color(0xFF00BCD4), // Cyan
  ];

  const BottomNavigationItem({
    super.key,
    required this.itemIndex,
    required this.notifier,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: InkWell(
        onTap: () {
          notifier.value = itemIndex;
        },
        child: ValueListenableBuilder(
          valueListenable: notifier,
          builder: (BuildContext context, _, __) {
            final isSelected = notifier.value == itemIndex;
            final isAIButton = itemIndex == 5; // AI Intelligence button

            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 15), // Lower the icons
                  _buildIcon(icon, isSelected, isAIButton),
                  SizedBox(height: 4),
                  !isSelected
                      ? SizedBox(width: 30, height: 20) // Reduced height placeholder
                      : Transform.rotate(
                          angle: -math.pi / 4,
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 150),
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              gradient: isAIButton
                                  ? LinearGradient(
                                      colors: _aiRainbowGradient,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isAIButton
                                  ? null
                                  : AppColors.primaryGreen,
                            ),
                          ),
                        ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIcon(IconData icon, bool isSelected, bool isAIButton) {
    if (isAIButton && isSelected) {
      return ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          colors: _aiRainbowGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
        blendMode: BlendMode.srcIn,
        child: Icon(icon, size: 30, color: Colors.white),
      );
    }
    return Icon(
      icon,
      size: 30,
      color: !isSelected
          ? Colors.grey
          : isAIButton
          ? Colors.white
          : AppColors.primaryText,
    );
  }
}
