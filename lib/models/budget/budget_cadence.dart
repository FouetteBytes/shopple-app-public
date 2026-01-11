import 'package:flutter/foundation.dart';

enum BudgetCadence { none, oneTime, weekly, monthly }

extension BudgetCadenceStorage on BudgetCadence {
  String get storageValue {
    switch (this) {
      case BudgetCadence.none:
        return 'none';
      case BudgetCadence.oneTime:
        return 'one_time';
      case BudgetCadence.weekly:
        return 'weekly';
      case BudgetCadence.monthly:
        return 'monthly';
    }
  }

  String get displayLabel {
    switch (this) {
      case BudgetCadence.none:
        return 'No Budget';
      case BudgetCadence.oneTime:
        return 'One-time';
      case BudgetCadence.weekly:
        return 'Weekly';
      case BudgetCadence.monthly:
        return 'Monthly';
    }
  }

  bool get isRecurring =>
      this == BudgetCadence.weekly || this == BudgetCadence.monthly;

  static BudgetCadence fromStorage(String? value) {
    switch (value) {
      case 'one_time':
        return BudgetCadence.oneTime;
      case 'weekly':
        return BudgetCadence.weekly;
      case 'monthly':
        return BudgetCadence.monthly;
      case 'none':
      case null:
        return BudgetCadence.none;
      default:
        debugPrint('Unknown budget cadence "$value"; defaulting to oneTime');
        return BudgetCadence.oneTime;
    }
  }
}
