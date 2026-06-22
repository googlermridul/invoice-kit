import 'package:intl/intl.dart';
import 'package:invoice_kit/core/constants/invoice_constants.dart';
import 'package:invoice_kit/core/extensions/datetime_extensions.dart';

class Formatters {
  Formatters._();

  /// Format money. Use [Money] for new code; this remains for backward use.
  static String currency(double amount, {String code = 'USD', String? symbol}) {
    final fmt = NumberFormat.currency(
      symbol: symbol ?? CurrencyCodes.symbolOf(code),
      decimalDigits: _decimalsFor(code),
    );
    return fmt.format(amount);
  }

  static int _decimalsFor(String code) {
    switch (code.toUpperCase()) {
      case 'JPY':
      case 'KRW':
      case 'VND':
      case 'IDR':
        return 0;
      default:
        return 2;
    }
  }

  static String number(num value) => NumberFormat('#,##0').format(value);

  static String compact(num value) => NumberFormat.compact().format(value);

  static String date(DateTime date, {String pattern = 'yyyy-MM-dd'}) => DateFormat(pattern).format(date);

  static String time(DateTime time) => DateFormat.jm().format(time);

  static String dateLong(DateTime date) => DateFormat.yMMMd().format(date);

  static String monthYear(DateTime date) => DateFormat.yMMM().format(date);

  static String relative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays.abs() > 7) return Formatters.date(date);
    return date.timeAgo();
  }
}
