/// ============================================================================
/// ফাইল: lib/presentation/widgets/user_status_widget.dart
/// স্তর: Presentation Widget | মডিউল: User Management
/// উদ্দেশ্য: User Management বা পুরো app-এ পুনর্ব্যবহারযোগ্য UI component প্রদান করে।
/// প্রধান অংশ: UserStatusWidget
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';

class UserStatusWidget extends StatelessWidget {
  const UserStatusWidget({super.key, required this.active});
  final bool active;
  @override
  Widget build(BuildContext context) => Text(
    active ? 'Active' : 'Inactive',
    style: TextStyle(
      color: active ? Colors.green : Colors.red,
      fontWeight: FontWeight.w600,
    ),
  );
}
