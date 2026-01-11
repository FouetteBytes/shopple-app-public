import 'package:flutter_test/flutter_test.dart';
import 'package:shopple/models/budget/budget_cadence.dart';
import 'package:shopple/models/budget/budget_period.dart';

/// Unit tests for budget models.
/// These tests verify budget model behavior without touching Firebase.
/// All data is created in-memory and isolated.

void main() {
  group('BudgetCadence Tests', () {
    group('storageValue', () {
      test('none returns correct storage value', () {
        expect(BudgetCadence.none.storageValue, equals('none'));
      });

      test('oneTime returns correct storage value', () {
        expect(BudgetCadence.oneTime.storageValue, equals('one_time'));
      });

      test('weekly returns correct storage value', () {
        expect(BudgetCadence.weekly.storageValue, equals('weekly'));
      });

      test('monthly returns correct storage value', () {
        expect(BudgetCadence.monthly.storageValue, equals('monthly'));
      });
    });

    group('displayLabel', () {
      test('none displays as No Budget', () {
        expect(BudgetCadence.none.displayLabel, equals('No Budget'));
      });

      test('oneTime displays as One-time', () {
        expect(BudgetCadence.oneTime.displayLabel, equals('One-time'));
      });

      test('weekly displays as Weekly', () {
        expect(BudgetCadence.weekly.displayLabel, equals('Weekly'));
      });

      test('monthly displays as Monthly', () {
        expect(BudgetCadence.monthly.displayLabel, equals('Monthly'));
      });
    });

    group('isRecurring', () {
      test('none is not recurring', () {
        expect(BudgetCadence.none.isRecurring, isFalse);
      });

      test('oneTime is not recurring', () {
        expect(BudgetCadence.oneTime.isRecurring, isFalse);
      });

      test('weekly is recurring', () {
        expect(BudgetCadence.weekly.isRecurring, isTrue);
      });

      test('monthly is recurring', () {
        expect(BudgetCadence.monthly.isRecurring, isTrue);
      });
    });

    group('fromStorage', () {
      test('parses none correctly', () {
        expect(
          BudgetCadenceStorage.fromStorage('none'),
          equals(BudgetCadence.none),
        );
      });

      test('parses one_time correctly', () {
        expect(
          BudgetCadenceStorage.fromStorage('one_time'),
          equals(BudgetCadence.oneTime),
        );
      });

      test('parses weekly correctly', () {
        expect(
          BudgetCadenceStorage.fromStorage('weekly'),
          equals(BudgetCadence.weekly),
        );
      });

      test('parses monthly correctly', () {
        expect(
          BudgetCadenceStorage.fromStorage('monthly'),
          equals(BudgetCadence.monthly),
        );
      });

      test('null defaults to none', () {
        expect(
          BudgetCadenceStorage.fromStorage(null),
          equals(BudgetCadence.none),
        );
      });

      test('unknown value defaults to oneTime', () {
        expect(
          BudgetCadenceStorage.fromStorage('invalid'),
          equals(BudgetCadence.oneTime),
        );
      });
    });

    group('round-trip', () {
      test('storageValue and fromStorage are inverse operations', () {
        for (final cadence in BudgetCadence.values) {
          final stored = cadence.storageValue;
          final restored = BudgetCadenceStorage.fromStorage(stored);
          expect(restored, equals(cadence));
        }
      });
    });
  });

  group('BudgetPeriod Tests', () {
    group('contains', () {
      test('date within period returns true', () {
        final period = BudgetPeriod(
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 1, 31),
          cadence: BudgetCadence.monthly,
        );

        expect(period.contains(DateTime(2024, 1, 15)), isTrue);
      });

      test('date before start returns false', () {
        final period = BudgetPeriod(
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 1, 31),
          cadence: BudgetCadence.monthly,
        );

        expect(period.contains(DateTime(2023, 12, 31)), isFalse);
      });

      test('date on or after end returns false', () {
        final period = BudgetPeriod(
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 1, 31),
          cadence: BudgetCadence.monthly,
        );

        expect(period.contains(DateTime(2024, 1, 31)), isFalse);
        expect(period.contains(DateTime(2024, 2, 1)), isFalse);
      });

      test('date at start boundary returns true', () {
        final period = BudgetPeriod(
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 1, 31),
          cadence: BudgetCadence.monthly,
        );

        expect(period.contains(DateTime(2024, 1, 1)), isTrue);
      });

      test('no end date means all future dates are contained', () {
        final period = BudgetPeriod(
          start: DateTime(2024, 1, 1),
          end: null,
          cadence: BudgetCadence.oneTime,
        );

        expect(period.contains(DateTime(2024, 1, 15)), isTrue);
        expect(period.contains(DateTime(2025, 6, 15)), isTrue);
        expect(period.contains(DateTime(2023, 12, 31)), isFalse);
      });
    });

    group('formattedLabel', () {
      test('none cadence returns appropriate label', () {
        final period = BudgetPeriod(
          start: DateTime(2024, 1, 1),
          cadence: BudgetCadence.none,
        );

        expect(period.formattedLabel(), equals('No active budget'));
      });

      test('oneTime cadence shows date range', () {
        final period = BudgetPeriod(
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 1, 16),
          cadence: BudgetCadence.oneTime,
        );

        final label = period.formattedLabel();
        expect(label, contains('Jan 1'));
        expect(label, contains('Jan 15'));
      });

      test('oneTime cadence without end shows since date', () {
        final period = BudgetPeriod(
          start: DateTime(2024, 1, 1),
          end: null,
          cadence: BudgetCadence.oneTime,
        );

        final label = period.formattedLabel();
        expect(label, startsWith('Since'));
        expect(label, contains('Jan 1'));
      });

      test('weekly cadence shows week range', () {
        final period = BudgetPeriod(
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 1, 8),
          cadence: BudgetCadence.weekly,
        );

        final label = period.formattedLabel();
        expect(label, contains('Jan 1'));
        expect(label, contains('Jan 7'));
      });

      test('monthly cadence shows month name', () {
        final period = BudgetPeriod(
          start: DateTime(2024, 3, 1),
          end: DateTime(2024, 4, 1),
          cadence: BudgetCadence.monthly,
        );

        final label = period.formattedLabel();
        expect(label, equals('March 2024'));
      });
    });

    group('construction', () {
      test('creates period with all parameters', () {
        final start = DateTime(2024, 1, 1);
        final end = DateTime(2024, 1, 31);
        final period = BudgetPeriod(
          start: start,
          end: end,
          cadence: BudgetCadence.monthly,
        );

        expect(period.start, equals(start));
        expect(period.end, equals(end));
        expect(period.cadence, equals(BudgetCadence.monthly));
      });

      test('end date can be null', () {
        final period = BudgetPeriod(
          start: DateTime(2024, 1, 1),
          end: null,
          cadence: BudgetCadence.oneTime,
        );

        expect(period.end, isNull);
      });
    });
  });
}
