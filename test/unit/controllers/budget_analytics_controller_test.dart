import 'package:flutter_test/flutter_test.dart';
import 'package:shopple/models/budget/budget_cadence.dart';
import 'package:shopple/models/budget/budget_period.dart';

/// Tests for budget-related models and logic
/// These tests verify budget model behavior without Firebase dependencies.
void main() {
  group('BudgetCadence Tests', () {
    test('none is not recurring', () {
      expect(BudgetCadence.none.isRecurring, isFalse);
    });

    test('weekly is recurring', () {
      expect(BudgetCadence.weekly.isRecurring, isTrue);
    });

    test('monthly is recurring', () {
      expect(BudgetCadence.monthly.isRecurring, isTrue);
    });

    test('storage values are correct', () {
      expect(BudgetCadence.none.storageValue, equals('none'));
      expect(BudgetCadence.oneTime.storageValue, equals('one_time'));
      expect(BudgetCadence.weekly.storageValue, equals('weekly'));
      expect(BudgetCadence.monthly.storageValue, equals('monthly'));
    });

    test('display labels are correct', () {
      expect(BudgetCadence.none.displayLabel, equals('No Budget'));
      expect(BudgetCadence.oneTime.displayLabel, equals('One-time'));
      expect(BudgetCadence.weekly.displayLabel, equals('Weekly'));
      expect(BudgetCadence.monthly.displayLabel, equals('Monthly'));
    });
  });

  group('BudgetPeriod Tests', () {
    test('contains date within period', () {
      final period = BudgetPeriod(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 31),
        cadence: BudgetCadence.monthly,
      );
      
      expect(period.contains(DateTime(2026, 1, 15)), isTrue);
    });

    test('does not contain date outside period', () {
      final period = BudgetPeriod(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 31),
        cadence: BudgetCadence.monthly,
      );
      
      expect(period.contains(DateTime(2026, 2, 1)), isFalse);
    });
  });
}
