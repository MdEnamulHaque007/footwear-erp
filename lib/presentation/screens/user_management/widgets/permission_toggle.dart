/// ============================================================================
/// ফাইল: lib/presentation/screens/user_management/widgets/permission_toggle.dart
/// স্তর: Presentation Screen | মডিউল: User Management
/// উদ্দেশ্য: User Management মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: PermissionToggle
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';

class PermissionToggle extends StatelessWidget {
  const PermissionToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) =>
      Switch(value: value, onChanged: onChanged);
}
