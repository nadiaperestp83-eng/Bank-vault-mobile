import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount, String currency) {
    final format = NumberFormat.currency(
      symbol: currency == 'USD' ? '\$' : 'KES ',
      decimalDigits: 2,
    );
    return format.format(amount);
  }

  static double convert(double amount, String from, String to, {double rate = 130.0}) {
    if (from == to) return amount;
    if (from == 'USD' && to == 'KES') return amount * rate;
    if (from == 'KES' && to == 'USD') return amount / rate;
    return amount;
  }
}
