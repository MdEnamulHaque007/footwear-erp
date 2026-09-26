/// ============================================================================
/// ফাইল: lib/core/constants/error_messages.dart
/// স্তর: Core | মডিউল: ERP Common
/// উদ্দেশ্য: Error Messages সম্পর্কিত shared configuration, utility, service বা application-wide behavior প্রদান করে।
/// প্রধান অংশ: ErrorMessages
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
class ErrorMessages {
  static const unknown = 'Something went wrong';
  static const network = 'Unable to connect to the service';
}
