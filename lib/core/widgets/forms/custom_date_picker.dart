/// ============================================================================
/// ফাইল: lib/core/widgets/forms/custom_date_picker.dart
/// স্তর: Presentation Widget | মডিউল: ERP Common
/// উদ্দেশ্য: ERP Common বা পুরো app-এ পুনর্ব্যবহারযোগ্য UI component প্রদান করে।
/// প্রধান অংশ: CustomDatePicker
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';

class CustomDatePicker extends StatelessWidget {
  const CustomDatePicker({super.key, required this.onSelected});
  final ValueChanged<DateTime> onSelected;
  @override
  Widget build(BuildContext context) => IconButton(
    icon: const Icon(Icons.calendar_month),
    onPressed: () async {
      final value = await showDatePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        initialDate: DateTime.now(),
      );
      if (value != null) onSelected(value);
    },
  );
}
