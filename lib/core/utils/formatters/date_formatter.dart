import 'package:intl/intl.dart';

class DateFormatter {
  static String format(DateTime value) =>
      DateFormat('yyyy-MM-dd').format(value);
}
