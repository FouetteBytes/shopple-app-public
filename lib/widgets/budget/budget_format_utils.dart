import 'package:intl/intl.dart';

final NumberFormat _currencyFormatter = NumberFormat.currency(
  symbol: 'Rs. ',
  decimalDigits: 0,
);
final NumberFormat _preciseCurrencyFormatter = NumberFormat.currency(
  symbol: 'Rs. ',
);
final NumberFormat _compactFormatter = NumberFormat.compactCurrency(
  symbol: 'Rs. ',
);
final NumberFormat _numberFormatter = NumberFormat('#,##0.##');

String formatCurrency(double value, {bool compact = false}) {
  if (compact) {
    return _compactFormatter.format(value);
  }
  if (value.abs() < 1000) {
    return _preciseCurrencyFormatter.format(value);
  }
  return _currencyFormatter.format(value);
}

String formatPlainNumber(double value) {
  return _numberFormatter.format(value);
}

String formatWeekRange(DateTime start, DateTime end) {
  final startFormat = DateFormat('MMM d');
  final endFormat = start.month == end.month
      ? DateFormat('d')
      : DateFormat('MMM d');
  return '${startFormat.format(start)} – ${endFormat.format(end)}';
}
