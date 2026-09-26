/// ============================================================================
/// ফাইল: lib/presentation/widgets/admin_sidebar_widget.dart
/// স্তর: Presentation Widget | মডিউল: ERP Common
/// উদ্দেশ্য: ERP Common বা পুরো app-এ পুনর্ব্যবহারযোগ্য UI component প্রদান করে।
/// প্রধান অংশ: AdminSidebarWidget
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminSidebarWidget extends StatelessWidget {
  const AdminSidebarWidget({super.key});
  @override
  Widget build(BuildContext context) => Drawer(
    child: ListView(
      children: [
        const DrawerHeader(child: Text('Admin Panel')),
        ListTile(leading: const Icon(Icons.dashboard), title: const Text('Overview'), onTap: () => context.go('/admin')),
        ListTile(leading: const Icon(Icons.people), title: const Text('Users'), onTap: () => context.go('/admin/users')),
        ListTile(leading: const Icon(Icons.badge), title: const Text('Roles'), onTap: () => context.go('/admin/roles')),
        ListTile(leading: const Icon(Icons.grid_on), title: const Text('Permissions'), onTap: () => context.go('/admin/permissions')),
        const Divider(),
        ListTile(leading: const Icon(Icons.storage), title: const Text('Demo Data Seeder'), onTap: () => context.go('/admin/demo-data')),
      ],
    ),
  );
}
