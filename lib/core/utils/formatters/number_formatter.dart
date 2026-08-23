import 'package:intl/intl.dart';

class NumberFormatter {
  static String format(num value) => NumberFormat('#,##0.##').format(value);
}
