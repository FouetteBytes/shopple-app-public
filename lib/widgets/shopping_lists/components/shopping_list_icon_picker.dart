import 'package:flutter/material.dart';
import 'package:shopple/constants/shopping_list_icons.dart';

class ShoppingListIconPicker extends StatelessWidget {
  final String selectedIconId;
  final Function(String) onIconSelected;
  final Color selectedColor;

  const ShoppingListIconPicker({
    super.key,
    required this.selectedIconId,
    required this.onIconSelected,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: ShoppingListIcons.all.length,
        itemBuilder: (context, index) {
          final icon = ShoppingListIcons.all[index];
          // Simple ID generation for demo purposes - in real app might map to string IDs
          final iconId = icon.codePoint.toString();
          final isSelected = selectedIconId == iconId || 
              (selectedIconId == 'shopping_cart' && index == 0); // Default fallback

          return InkWell(
            onTap: () => onIconSelected(iconId),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? selectedColor.withValues(alpha: 0.2) : Colors.transparent,
                border: isSelected
                    ? Border.all(color: selectedColor, width: 2)
                    : Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? selectedColor : Colors.grey,
                size: 24,
              ),
            ),
          );
        },
      ),
    );
  }
}
