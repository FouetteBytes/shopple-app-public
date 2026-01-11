import 'package:flutter/material.dart';

class ColorPickerWidget extends StatelessWidget {
  final String selectedColor;
  final Function(String) onColorSelected;

  const ColorPickerWidget({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  static const List<String> themeColors = [
    '#4CAF50', // Green
    '#2196F3', // Blue
    '#FF9800', // Orange
    '#9C27B0', // Purple
    '#F44336', // Red
    '#009688', // Teal
    '#795548', // Brown
    '#607D8B', // Blue Grey
    '#E91E63', // Pink
    '#FF5722', // Deep Orange
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: themeColors.length,
        itemBuilder: (context, index) {
          final colorHex = themeColors[index];
          final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
          final isSelected = selectedColor == colorHex;

          return Padding(
            padding: EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => onColorSelected(colorHex),
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: isSelected
                    ? Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
