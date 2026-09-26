/// ============================================================================
/// ফাইল: lib/presentation/screens/auth/unauthorized_screen.dart
/// স্তর: Presentation Screen | মডিউল: Authentication
/// উদ্দেশ্য: Authentication মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: UnauthorizedScreen
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../routes/route_constants.dart';

class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Access denied')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('You do not have permission to view this page.'),
          TextButton(
            onPressed: () => context.go(RouteConstants.dashboard),
            child: const Text('Back to dashboard'),
          ),
        ],
      ),
    ),
  );
}
