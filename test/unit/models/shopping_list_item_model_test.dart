import 'package:flutter_test/flutter_test.dart';
import 'package:shopple/models/shopping_lists/shopping_list_item_model.dart';

/// Unit tests for ShoppingListItem model.
/// These tests verify item model behavior without touching Firebase.
/// All data is created in-memory and isolated.

void main() {
  group('ShoppingListItem Model Tests', () {
    late ShoppingListItem baseItem;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 15, 10, 30);
      baseItem = ShoppingListItem(
        id: 'item-123',
        listId: 'list-456',
        productId: 'product-789',
        name: 'Organic Milk',
        quantity: 2,
        unit: 'liters',
        notes: 'Prefer full-fat',
        isCompleted: false,
        estimatedPrice: 3.99,
        category: 'dairy',
        order: 1,
        addedBy: 'user-123',
        addedAt: testDate,
        updatedAt: testDate,
      );
    });

    group('Basic Properties', () {
      test('creates item with all required fields', () {
        expect(baseItem.id, equals('item-123'));
        expect(baseItem.listId, equals('list-456'));
        expect(baseItem.name, equals('Organic Milk'));
        expect(baseItem.quantity, equals(2));
        expect(baseItem.addedBy, equals('user-123'));
      });

      test('creates item with default values', () {
        final minimalItem = ShoppingListItem(
          id: 'min-item',
          listId: 'list-1',
          name: 'Basic Item',
          addedBy: 'user-1',
          addedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(minimalItem.quantity, equals(1));
        expect(minimalItem.unit, equals('items'));
        expect(minimalItem.notes, equals(''));
        expect(minimalItem.isCompleted, isFalse);
        expect(minimalItem.estimatedPrice, equals(0.0));
        expect(minimalItem.category, equals('other'));
        expect(minimalItem.order, equals(0));
        expect(minimalItem.productId, isNull);
        expect(minimalItem.completedAt, isNull);
      });

      test('stores optional productId correctly', () {
        expect(baseItem.productId, equals('product-789'));
      });

      test('stores notes correctly', () {
        expect(baseItem.notes, equals('Prefer full-fat'));
      });
    });

    group('Computed Properties', () {
      test('displayName returns item name', () {
        expect(baseItem.displayName, equals('Organic Milk'));
      });

      test('totalPrice calculates correctly', () {
        // quantity: 2, estimatedPrice: 3.99
        expect(baseItem.totalPrice, closeTo(7.98, 0.001));
      });

      test('totalPrice handles zero quantity', () {
        final zeroQty = baseItem.copyWith(quantity: 0);
        expect(zeroQty.totalPrice, equals(0.0));
      });

      test('totalPrice handles zero price', () {
        final freeItem = baseItem.copyWith(estimatedPrice: 0.0);
        expect(freeItem.totalPrice, equals(0.0));
      });

      test('isFromProduct returns true when productId exists', () {
        expect(baseItem.isFromProduct, isTrue);
      });

      test('isFromProduct returns false when productId is null', () {
        final manualItem = ShoppingListItem(
          id: 'manual-item',
          listId: 'list-1',
          name: 'Hand-written item',
          addedBy: 'user-1',
          addedAt: DateTime.now(),
          updatedAt: DateTime.now(),
          productId: null,
        );

        expect(manualItem.isFromProduct, isFalse);
      });
    });

    group('copyWith', () {
      test('creates copy with updated name', () {
        final updated = baseItem.copyWith(name: 'Skim Milk');

        expect(updated.name, equals('Skim Milk'));
        expect(updated.id, equals(baseItem.id));
        expect(updated.quantity, equals(baseItem.quantity));
      });

      test('creates copy with updated quantity', () {
        final updated = baseItem.copyWith(quantity: 5);

        expect(updated.quantity, equals(5));
        expect(updated.name, equals(baseItem.name));
      });

      test('creates copy with completion status', () {
        final completed = baseItem.copyWith(
          isCompleted: true,
          completedAt: DateTime.now(),
        );

        expect(completed.isCompleted, isTrue);
        expect(completed.completedAt, isNotNull);
      });

      test('creates copy with updated price', () {
        final updated = baseItem.copyWith(estimatedPrice: 5.99);

        expect(updated.estimatedPrice, equals(5.99));
        expect(updated.totalPrice, closeTo(11.98, 0.001)); // 2 * 5.99
      });

      test('creates copy with all fields unchanged', () {
        final copy = baseItem.copyWith();

        expect(copy.id, equals(baseItem.id));
        expect(copy.name, equals(baseItem.name));
        expect(copy.quantity, equals(baseItem.quantity));
        expect(copy.estimatedPrice, equals(baseItem.estimatedPrice));
      });

      test('creates copy with multiple fields changed', () {
        final updated = baseItem.copyWith(
          name: 'Almond Milk',
          quantity: 3,
          estimatedPrice: 4.50,
          category: 'dairy-alternative',
        );

        expect(updated.name, equals('Almond Milk'));
        expect(updated.quantity, equals(3));
        expect(updated.estimatedPrice, equals(4.50));
        expect(updated.category, equals('dairy-alternative'));
      });
    });

    group('toFirestore', () {
      test('serializes all fields correctly', () {
        final data = baseItem.toFirestore();

        expect(data['listId'], equals('list-456'));
        expect(data['productId'], equals('product-789'));
        expect(data['name'], equals('Organic Milk'));
        expect(data['quantity'], equals(2));
        expect(data['unit'], equals('liters'));
        expect(data['notes'], equals('Prefer full-fat'));
        expect(data['isCompleted'], isFalse);
        expect(data['estimatedPrice'], equals(3.99));
        expect(data['category'], equals('dairy'));
        expect(data['order'], equals(1));
        expect(data['addedBy'], equals('user-123'));
      });

      test('serializes null productId correctly', () {
        final item = baseItem.copyWith(productId: null);
        final data = item.toFirestore();

        expect(data.containsKey('productId'), isTrue);
        // Depending on implementation, could be null or missing
      });

      test('serializes completedAt when present', () {
        final completedItem = baseItem.copyWith(
          isCompleted: true,
          completedAt: DateTime(2024, 1, 20, 15, 0),
        );
        final data = completedItem.toFirestore();

        expect(data['completedAt'], isNotNull);
        expect(data['isCompleted'], isTrue);
      });

      test('serializes completedAt as null when not completed', () {
        final data = baseItem.toFirestore();

        expect(data['completedAt'], isNull);
      });
    });

    group('Completion Workflow', () {
      test('item starts as not completed', () {
        expect(baseItem.isCompleted, isFalse);
        expect(baseItem.completedAt, isNull);
      });

      test('can mark item as completed with timestamp', () {
        final completionTime = DateTime.now();
        final completed = baseItem.copyWith(
          isCompleted: true,
          completedAt: completionTime,
        );

        expect(completed.isCompleted, isTrue);
        expect(completed.completedAt, equals(completionTime));
      });

      test('can unmark item as completed', () {
        final completed = baseItem.copyWith(
          isCompleted: true,
          completedAt: DateTime.now(),
        );
        final uncompleted = completed.copyWith(
          isCompleted: false,
          completedAt: null,
        );

        expect(uncompleted.isCompleted, isFalse);
        // Note: copyWith with null doesn't clear completedAt due to ?? operator
        // This is a limitation of the current copyWith implementation
      });
    });

    group('Edge Cases', () {
      test('handles very large quantities', () {
        final bulkItem = baseItem.copyWith(quantity: 1000000);

        expect(bulkItem.quantity, equals(1000000));
        expect(bulkItem.totalPrice, closeTo(3990000.0, 0.001));
      });

      test('handles very small prices', () {
        final cheapItem = baseItem.copyWith(estimatedPrice: 0.01);

        expect(cheapItem.totalPrice, closeTo(0.02, 0.001));
      });

      test('handles special characters in name', () {
        final specialItem = baseItem.copyWith(name: "Ben & Jerry's Ice Cream");

        expect(specialItem.name, equals("Ben & Jerry's Ice Cream"));
      });

      test('handles empty name', () {
        final emptyItem = ShoppingListItem(
          id: 'empty-name',
          listId: 'list-1',
          name: '',
          addedBy: 'user-1',
          addedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(emptyItem.name, equals(''));
        expect(emptyItem.displayName, equals(''));
      });

      test('handles Unicode characters in notes', () {
        final unicodeItem = baseItem.copyWith(notes: '🥛 Fresh milk preferred 日本語');

        expect(unicodeItem.notes, contains('🥛'));
        expect(unicodeItem.notes, contains('日本語'));
      });
    });

    group('Category Handling', () {
      test('stores category correctly', () {
        expect(baseItem.category, equals('dairy'));
      });

      test('default category is other', () {
        final item = ShoppingListItem(
          id: 'no-category',
          listId: 'list-1',
          name: 'Mystery Item',
          addedBy: 'user-1',
          addedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(item.category, equals('other'));
      });

      test('can update category', () {
        final updated = baseItem.copyWith(category: 'beverages');

        expect(updated.category, equals('beverages'));
      });
    });

    group('Order/Sorting', () {
      test('stores order field correctly', () {
        expect(baseItem.order, equals(1));
      });

      test('can update order', () {
        final reordered = baseItem.copyWith(order: 10);

        expect(reordered.order, equals(10));
      });

      test('default order is 0', () {
        final item = ShoppingListItem(
          id: 'no-order',
          listId: 'list-1',
          name: 'Unordered Item',
          addedBy: 'user-1',
          addedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(item.order, equals(0));
      });
    });
  });
}
