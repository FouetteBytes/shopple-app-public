import 'package:intl/intl.dart';
import 'package:shopple/models/budget/budget_cadence.dart';

class BudgetPeriod {
  const BudgetPeriod({required this.start, this.end, required this.cadence});

  final DateTime start;
  final DateTime? end; // exclusive end when provided
  final BudgetCadence cadence;

  bool contains(DateTime value) {
    final normalized = DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
      value.millisecond,
      value.microsecond,
    );
    if (normalized.isBefore(start)) return false;
    if (end == null) return true;
    return normalized.isBefore(end!);
  }

  String formattedLabel() {
    final dateFormat = DateFormat('MMM d');
    switch (cadence) {
      case BudgetCadence.none:
        return 'No active budget';
      case BudgetCadence.oneTime:
        final endLabel = end != null
            ? ' – ${dateFormat.format(end!.subtract(const Duration(days: 1)))}'
            : '';
        return 'Since ${dateFormat.format(start)}$endLabel';
      case BudgetCadence.weekly:
        final endDisplay = end != null
            ? end!.subtract(const Duration(days: 1))
            : start.add(const Duration(days: 6));
        return '${dateFormat.format(start)} – ${dateFormat.format(endDisplay)}';
      case BudgetCadence.monthly:
        final monthLabel = DateFormat('MMMM yyyy');
        return monthLabel.format(start);
    }
  }
}
