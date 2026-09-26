/// ============================================================================
/// ফাইল: lib/core/utils/field_parsers.dart
/// স্তর: Core | মডিউল: ERP Common
/// উদ্দেশ্য: Field Parsers সম্পর্কিত shared configuration, utility, service বা application-wide behavior প্রদান করে।
/// প্রধান অংশ: top-level configuration ও helper declarations
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
/// Typed parsing helpers for form fields.
///
/// These centralize the "tryParse with a safe fallback" pattern so numeric
/// form fields never leak raw parse failures into the domain layer.
library;

/// Parses [text] as an int, returning 0 when null, empty or malformed.
int parseInt(String? text) => int.tryParse(text?.trim() ?? '') ?? 0;

/// Parses [text] as a double, returning 0 when null, empty or malformed.
double parseDouble(String? text) => double.tryParse(text?.trim() ?? '') ?? 0;
