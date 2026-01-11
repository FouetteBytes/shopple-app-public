// Project/task themed shopping list cards (vertical + horizontal)
// Refactored into smaller components in lib/widgets/shopping_lists/cards/

import 'package:flutter/material.dart';
import 'package:shopple/models/shopping_lists/shopping_list_model.dart';

import 'cards/shopping_list_card_vertical.dart';
import 'cards/shopping_list_card_horizontal.dart';

export 'cards/shopping_list_card_helpers.dart';
export 'cards/shopping_list_card_images.dart';
export 'cards/shopping_list_card_members.dart';
export 'cards/shopping_list_card_vertical.dart';
export 'cards/shopping_list_card_horizontal.dart';

// Backward compatibility legacy names as concrete forwarding widgets
class ShoppingListCardHorizontalLegacy extends StatelessWidget {
  final ShoppingList list;
  final VoidCallback? onTap;
  const ShoppingListCardHorizontalLegacy({
    super.key,
    required this.list,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) =>
      ShoppingListCardHorizontal(list: list, onTap: onTap);
}

class ShoppingListCardVerticalLegacy extends StatelessWidget {
  final ShoppingList list;
  final VoidCallback? onTap;
  const ShoppingListCardVerticalLegacy({
    super.key,
    required this.list,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) =>
      ShoppingListCardVertical(list: list, onTap: onTap);
}
