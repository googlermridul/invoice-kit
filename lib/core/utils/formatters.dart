import 'package:flutter_boilerplate/core/extensions/datetime_extensions.dart';
import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static String currency(double amount, {String symbol = r'$'}) =>
      '$symbol${NumberFormat('#,##0.00').format(amount)}';

  static String number(num value) => NumberFormat('#,##0').format(value);

  static String compact(num value) => NumberFormat.compact().format(value);

  static String date(DateTime date, {String pattern = 'yyyy-MM-dd'}) =>
      DateFormat(pattern).format(date);

  static String time(DateTime time) => DateFormat.jm().format(time);

  static String relative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays.abs() > 7) {
      return Formatters.date(date);
    }
    return date.timeAgo();
  }
}
