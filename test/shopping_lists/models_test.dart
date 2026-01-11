import 'package:flutter_test/flutter_test.dart';
import 'package:shopple/models/shopping_lists/shopping_list_model.dart';
import 'package:shopple/models/shopping_lists/shopping_list_item_model.dart';

void main() {
  group('ShoppingList model', () {
    test('completion percentage & isCompleted', () {
      final now = DateTime.now();
      final list = ShoppingList(
        id: 'l1',
        name: 'Groceries',
        createdBy: 'u1',
        createdAt: now,
        updatedAt: now,
        lastActivity: now,
        totalItems: 5,
        completedItems: 2,
      );
      expect(list.completionPercentage, closeTo(40.0, 0.01));
      expect(list.isCompleted, false);
    });
  });

  group('ShoppingListItem model', () {
    test('total price & copyWith', () {
      final now = DateTime.now();
      final item = ShoppingListItem(
        id: 'i1',
        listId: 'l1',
        name: 'Milk',
        quantity: 2,
        estimatedPrice: 150,
        addedBy: 'u1',
        addedAt: now,
        updatedAt: now,
      );
      expect(item.totalPrice, 300);
      final updated = item.copyWith(quantity: 3, estimatedPrice: 100);
      expect(updated.totalPrice, 300);
      expect(updated.quantity, 3);
      expect(updated.estimatedPrice, 100);
    });
  });
}
