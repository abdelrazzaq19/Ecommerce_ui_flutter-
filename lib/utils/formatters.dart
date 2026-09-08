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
