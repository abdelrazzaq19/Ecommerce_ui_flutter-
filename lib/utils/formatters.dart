import 'package:intl/intl.dart';

/// Money formatting for the whole app.
///
/// Prices were previously interpolated straight from a double, which rendered
/// `$219.9` and, once quantities multiplied in, floating-point noise like
/// `$65.69999999999999`.
final NumberFormat _currency = NumberFormat.currency(
  locale: 'en_US',
  symbol: r'$',
  decimalDigits: 2,
);

/// Formats [amount] as a price, e.g. `1234.5` becomes `$1,234.50`.
String formatPrice(double amount) => _currency.format(amount);

final NumberFormat _compact = NumberFormat.compact(locale: 'en_US');

/// Formats a review count, e.g. `1200` becomes `1.2K`.
String formatCount(int count) => _compact.format(count);

final DateFormat _dateTime = DateFormat('d MMM yyyy, HH:mm', 'en_US');
final DateFormat _date = DateFormat('d MMM yyyy', 'en_US');

/// `9 Sep 2026, 14:05` — for an order receipt.
String formatDateTime(DateTime value) => _dateTime.format(value);

/// `9 Sep 2026` — for an order history row.
String formatDate(DateTime value) => _date.format(value);
