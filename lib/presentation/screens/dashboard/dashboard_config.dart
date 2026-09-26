/// ============================================================================
/// ফাইল: lib/presentation/screens/dashboard/dashboard_config.dart
/// স্তর: Presentation Screen | মডিউল: Dashboard
/// উদ্দেশ্য: Dashboard মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: DashboardConfig
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
class DashboardConfig {
  static const modules = <String>[
    'Master LC',
    'Purchase Order',
    'Cutting',
    'Sewing',
    'Production',
    'Issue',
    'Export',
  ];
}
