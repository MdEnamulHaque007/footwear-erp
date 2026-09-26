/// ============================================================================
/// ফাইল: lib/core/utils/formatters/date_formatter.dart
/// স্তর: Core | মডিউল: ERP Common
/// উদ্দেশ্য: Date Formatter সম্পর্কিত shared configuration, utility, service বা application-wide behavior প্রদান করে।
/// প্রধান অংশ: DateFormatter
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:intl/intl.dart';

class DateFormatter {
  static String format(DateTime value) =>
      DateFormat('yyyy-MM-dd').format(value);
}
