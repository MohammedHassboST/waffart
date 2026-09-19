import 'package:intl/intl.dart';

class Formatters {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'ar_EG',
    symbol: 'ج.م',
    decimalDigits: 2,
  );

  static final _dateFormat = DateFormat('yyyy/MM/dd', 'ar');
  static final _dateTimeFormat = DateFormat('yyyy/MM/dd HH:mm', 'ar');

  static String currency(num value) => _currencyFormat.format(value);
  static String date(DateTime date) => _dateFormat.format(date);
  static String dateTime(DateTime date) => _dateTimeFormat.format(date);

  static String relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inDays < 1) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return _dateFormat.format(date);
  }
}