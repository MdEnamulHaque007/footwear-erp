/// ============================================================================
/// ফাইল: lib/core/services/local/cache_service.dart
/// স্তর: Core | মডিউল: ERP Common
/// উদ্দেশ্য: Cache Service সম্পর্কিত shared configuration, utility, service বা application-wide behavior প্রদান করে।
/// প্রধান অংশ: CacheService
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
class CacheService {
  final Map<String, Object?> _values = {};
  Object? read(String key) => _values[key];
  void write(String key, Object? value) => _values[key] = value;
}
