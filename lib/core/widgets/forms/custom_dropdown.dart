/// ============================================================================
/// ফাইল: lib/core/widgets/forms/custom_dropdown.dart
/// স্তর: Presentation Widget | মডিউল: ERP Common
/// উদ্দেশ্য: ERP Common বা পুরো app-এ পুনর্ব্যবহারযোগ্য UI component প্রদান করে।
/// প্রধান অংশ: CustomDropdown
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';

class CustomDropdown<T> extends StatelessWidget {
  const CustomDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  @override
  Widget build(BuildContext context) =>
      DropdownButton<T>(value: value, items: items, onChanged: onChanged);
}
