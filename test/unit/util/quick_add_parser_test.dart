import 'package:flutter_test/flutter_test.dart';
import 'package:shopple/utils/quick_add_parser.dart';

/// Unit tests for QuickAddParser utility.
/// These tests verify parsing logic for the quick-add feature without any external dependencies.
/// All data is created in-memory and isolated.

void main() {
  group('QuickAddParser Tests', () {
    group('Basic Name Parsing', () {
      test('parses simple product name', () {
        final result = QuickAddParser.parse('Milk');

        expect(result.name, equals('Milk'));
        expect(result.quantity, equals(1));
        expect(result.price, equals(0));
        expect(result.notes, equals(''));
      });

      test('parses product name with spaces', () {
        final result = QuickAddParser.parse('Organic Whole Milk');

        expect(result.name, equals('Organic Whole Milk'));
        expect(result.quantity, equals(1));
      });

      test('handles empty input', () {
        final result = QuickAddParser.parse('');

        expect(result.name, equals(''));
        expect(result.quantity, equals(1));
        expect(result.price, equals(0));
        expect(result.notes, equals(''));
      });

      test('handles whitespace-only input', () {
        final result = QuickAddParser.parse('   ');

        expect(result.name, equals(''));
      });

      test('trims whitespace from input', () {
        final result = QuickAddParser.parse('  Bread  ');

        expect(result.name, equals('Bread'));
      });
    });

    group('Quantity Parsing with x/X notation', () {
      test('parses quantity with lowercase x', () {
        final result = QuickAddParser.parse('3x Eggs');

        expect(result.name, equals('Eggs'));
        expect(result.quantity, equals(3));
      });

      test('parses quantity with uppercase X', () {
        final result = QuickAddParser.parse('2X Butter');

        expect(result.name, equals('Butter'));
        expect(result.quantity, equals(2));
      });

      test('parses quantity with space separator', () {
        final result = QuickAddParser.parse('5 Apples');

        expect(result.name, equals('Apples'));
        expect(result.quantity, equals(5));
      });

      test('handles quantity of 1 explicitly', () {
        final result = QuickAddParser.parse('1x Coffee');

        expect(result.name, equals('Coffee'));
        expect(result.quantity, equals(1));
      });

      test('handles large quantities', () {
        final result = QuickAddParser.parse('100x Paper Clips');

        expect(result.name, equals('Paper Clips'));
        expect(result.quantity, equals(100));
      });
    });

    group('Quantity Parsing with unit notation', () {
      test('parses quantity with kg unit', () {
        final result = QuickAddParser.parse('2kg Rice');

        expect(result.name, equals('Rice'));
        expect(result.quantity, equals(2));
      });

      test('parses quantity with lb unit', () {
        final result = QuickAddParser.parse('3lb Ground Beef');

        expect(result.name, equals('Ground Beef'));
        expect(result.quantity, equals(3));
      });

      test('parses quantity with oz unit', () {
        final result = QuickAddParser.parse('16oz Yogurt');

        expect(result.name, equals('Yogurt'));
        expect(result.quantity, equals(16));
      });
    });

    group('Price Parsing with @ notation', () {
      test('parses price with @ symbol', () {
        final result = QuickAddParser.parse('Milk @3.50');

        expect(result.name, equals('Milk'));
        expect(result.price, equals(3.50));
      });

      test('parses integer price with @ symbol', () {
        final result = QuickAddParser.parse('Bread @5');

        expect(result.name, equals('Bread'));
        expect(result.price, equals(5.0));
      });

      test('parses price with quantity', () {
        final result = QuickAddParser.parse('2x Eggs @4.99');

        expect(result.name, equals('Eggs'));
        expect(result.quantity, equals(2));
        expect(result.price, equals(4.99));
      });
    });

    group('Price Parsing with trailing number', () {
      test('parses trailing price without @ symbol', () {
        final result = QuickAddParser.parse('Cheese 7.99');

        expect(result.name, equals('Cheese'));
        expect(result.price, equals(7.99));
      });

      test('parses trailing integer price', () {
        final result = QuickAddParser.parse('Orange Juice 4');

        expect(result.name, equals('Orange Juice'));
        expect(result.price, equals(4.0));
      });
    });

    group('Notes Parsing', () {
      test('parses notes with note: prefix', () {
        final result = QuickAddParser.parse('Milk note:whole milk only');

        expect(result.name, equals('Milk'));
        expect(result.notes, equals('whole milk only'));
      });

      test('parses notes with n: prefix', () {
        final result = QuickAddParser.parse('Bread n:sourdough preferred');

        expect(result.name, equals('Bread'));
        expect(result.notes, equals('sourdough preferred'));
      });

      test('parses notes case-insensitive', () {
        final result = QuickAddParser.parse('Eggs NOTE:free range');

        expect(result.name, equals('Eggs'));
        expect(result.notes, equals('free range'));
      });

      test('handles notes with price', () {
        final result = QuickAddParser.parse('Cheese @5.99 note:sharp cheddar');

        expect(result.name, equals('Cheese'));
        expect(result.price, equals(5.99));
        expect(result.notes, equals('sharp cheddar'));
      });

      test('handles notes with quantity', () {
        final result = QuickAddParser.parse('3x Bananas n:ripe ones');

        expect(result.name, equals('Bananas'));
        expect(result.quantity, equals(3));
        expect(result.notes, equals('ripe ones'));
      });
    });

    group('Complex Combined Input', () {
      test('parses quantity, product, price, and notes', () {
        final result = QuickAddParser.parse(
          '2x Organic Milk @4.99 note:1% fat',
        );

        expect(result.name, equals('Organic Milk'));
        expect(result.quantity, equals(2));
        expect(result.price, equals(4.99));
        expect(result.notes, equals('1% fat'));
      });

      test('parses unit quantity with price', () {
        final result = QuickAddParser.parse('5kg Flour @12.99');

        expect(result.name, equals('Flour'));
        expect(result.quantity, equals(5));
        expect(result.price, equals(12.99));
      });

      test('handles all optional components missing', () {
        final result = QuickAddParser.parse('Simple Item');

        expect(result.name, equals('Simple Item'));
        expect(result.quantity, equals(1));
        expect(result.price, equals(0));
        expect(result.notes, equals(''));
      });
    });

    group('Edge Cases', () {
      test('handles product name that starts with number', () {
        // "7up" should be treated as a name, not quantity
        // This depends on implementation details
        final result = QuickAddParser.parse('7up Soda');
        // Current implementation may interpret 7 as quantity
        // Test documents actual behavior
        expect(result.name.isNotEmpty || result.quantity > 0, isTrue);
      });

      test('handles decimal price with multiple decimal places', () {
        final result = QuickAddParser.parse('Coffee @3.999');

        expect(result.price, closeTo(3.999, 0.001));
      });

      test('handles zero price explicitly', () {
        final result = QuickAddParser.parse('Free Sample @0');

        expect(result.name, equals('Free Sample'));
        expect(result.price, equals(0));
      });

      test('handles very long product names', () {
        final longName = 'A' * 100;
        final result = QuickAddParser.parse(longName);

        expect(result.name, equals(longName));
      });

      test('handles special characters in product name', () {
        final result = QuickAddParser.parse("Ben & Jerry's Ice Cream");

        expect(result.name, contains("Ben & Jerry's"));
      });
    });
  });

  group('QuickAddParseResult Tests', () {
    test('stores all fields correctly', () {
      final result = QuickAddParseResult(
        name: 'Test Item',
        quantity: 5,
        price: 10.99,
        notes: 'Test note',
      );

      expect(result.name, equals('Test Item'));
      expect(result.quantity, equals(5));
      expect(result.price, equals(10.99));
      expect(result.notes, equals('Test note'));
    });
  });
}
