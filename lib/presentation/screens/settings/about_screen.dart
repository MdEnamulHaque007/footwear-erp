/// ============================================================================
/// ফাইল: lib/presentation/screens/settings/about_screen.dart
/// স্তর: Presentation Screen | মডিউল: Settings
/// উদ্দেশ্য: Settings মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: AboutScreen, _SectionHeader
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/color_palette.dart';
import '../../widgets/app_drawer.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    drawer: const AppDrawer(),
    appBar: AppBar(
      leadingWidth: 96,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/settings'),
          ),
          Builder(
            builder: (drawerContext) => IconButton(
              tooltip: 'Menu',
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(drawerContext).openDrawer(),
            ),
          ),
        ],
      ),
      title: const Text('About Us'),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Container(
                  height: 72,
                  width: 72,
                  decoration: BoxDecoration(
                    color: ColorPalette.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.precision_manufacturing_outlined,
                    color: ColorPalette.primary,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  AppConstants.appName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'A unified workspace for footwear production operations, tracking, and reporting.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ColorPalette.muted),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionHeader('APPLICATION'),
        Card(
          child: Column(
            children: [
              _infoRow(
                icon: Icons.info_outline,
                label: 'Version',
                value: 'v${AppConstants.appVersion}',
              ),
              const Divider(height: 1),
              _infoRow(
                icon: Icons.business_outlined,
                label: 'Business',
                value: 'IALT Footwear Ltd.',
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.content_copy_outlined,
                  color: ColorPalette.primary,
                ),
                title: const Text('Copy version information'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _copyVersion(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _SectionHeader('ABOUT'),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'This application helps teams manage master LCs, purchase orders, cutting, sewing, production, issues, exports, and reporting from one secure system.',
              style: TextStyle(color: ColorPalette.muted, height: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '© 2026 IALT Footwear Ltd. All rights reserved.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: ColorPalette.muted, fontSize: 12),
        ),
      ],
    ),
  );

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) => ListTile(
    leading: Icon(icon, color: ColorPalette.primary),
    title: Text(label),
    trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
  );

  Future<void> _copyVersion(BuildContext context) async {
    await Clipboard.setData(
      ClipboardData(
        text: '${AppConstants.appName} v${AppConstants.appVersion}',
      ),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Version information copied to clipboard.')),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: const TextStyle(
        color: ColorPalette.muted,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    ),
  );
}
