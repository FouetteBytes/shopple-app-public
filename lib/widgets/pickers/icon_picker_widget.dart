import 'package:flutter/material.dart';
import '../../values/values.dart';

class IconPickerWidget extends StatelessWidget {
  final String selectedIconId;
  final Function(String) onIconSelected;

  const IconPickerWidget({
    super.key,
    required this.selectedIconId,
    required this.onIconSelected,
  });

  static const Map<String, IconData> shoppingListIcons = {
    'shopping_cart': Icons.shopping_cart,
    'local_grocery_store': Icons.local_grocery_store,
    'restaurant': Icons.restaurant,
    'local_pharmacy': Icons.local_pharmacy,
    'pets': Icons.pets,
    'build': Icons.build,
    'home': Icons.home,
    'work': Icons.work,
    'favorite': Icons.favorite,
    'child_care': Icons.child_care,
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: shoppingListIcons.length,
        itemBuilder: (context, index) {
          final iconEntry = shoppingListIcons.entries.elementAt(index);
          final iconId = iconEntry.key;
          final iconData = iconEntry.value;
          final isSelected = selectedIconId == iconId;

          return InkWell(
            onTap: () => onIconSelected(iconId),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryAccentColor.withValues(alpha: 0.2)
                    : AppColors.background.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryAccentColor
                      : Colors.grey[700]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Icon(
                iconData,
                color: isSelected
                    ? AppColors.primaryAccentColor
                    : Colors.grey[400],
                size: 24,
              ),
            ),
          );
        },
      ),
    );
  }
}
