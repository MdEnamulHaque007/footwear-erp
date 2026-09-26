/// ============================================================================
/// ফাইল: lib/presentation/screens/settings/data_management_screen.dart
/// স্তর: Presentation Screen | মডিউল: Settings
/// উদ্দেশ্য: Settings মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: DataManagementScreen, _DataManagementScreenState, _SectionHeader, _AdminOnlyMessage
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/color_palette.dart';
import '../../../domain/entities/settings/business_settings_entity.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/settings/settings_bloc.dart';
import '../../blocs/settings/settings_event.dart';
import '../../blocs/settings/settings_state.dart';
import '../../widgets/app_drawer.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SettingsBloc>().add(const LoadBusinessSettings());
      }
    });
  }

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
      title: const Text('Data Management'),
    ),
    body: BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated || !authState.user.isAdmin) {
          return const _AdminOnlyMessage();
        }
        return BlocConsumer<SettingsBloc, SettingsState>(
          listener: (context, state) {
            if (state is SettingsSaved || state is SettingsError) {
              final message = state is SettingsSaved
                  ? state.message
                  : (state as SettingsError).message;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(message)));
            }
          },
          builder: (context, state) {
            if (state is SettingsLoading || state is SettingsInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is SettingsError) return _retry();
            return _content(
              context.read<SettingsBloc>().currentBusinessSettings,
            );
          },
        );
      },
    ),
  );

  Widget _retry() => Center(
    child: FilledButton.icon(
      onPressed: () =>
          context.read<SettingsBloc>().add(const LoadBusinessSettings()),
      icon: const Icon(Icons.refresh),
      label: const Text('Try again'),
    ),
  );

  Widget _content(BusinessSettingsEntity settings) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
    children: [
      const _SectionHeader('SETTINGS BACKUP'),
      Card(
        child: ListTile(
          leading: const Icon(
            Icons.content_copy_outlined,
            color: ColorPalette.primary,
          ),
          title: const Text('Copy business settings backup'),
          subtitle: const Text(
            'Copy company, factory, project, brand, article, and color settings as JSON.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _copyBackup(settings),
        ),
      ),
      const SizedBox(height: 20),
      const _SectionHeader('SETTINGS SUMMARY'),
      Card(
        child: Column(
          children: [
            _summaryRow(
              Icons.business_outlined,
              'Company',
              settings.companyName,
            ),
            const Divider(height: 1),
            _summaryRow(
              Icons.factory_outlined,
              'Factories',
              '${settings.factoryList.length}',
            ),
            const Divider(height: 1),
            _summaryRow(
              Icons.folder_outlined,
              'Projects',
              '${settings.projectList.length}',
            ),
            const Divider(height: 1),
            _summaryRow(
              Icons.sell_outlined,
              'Brands',
              '${settings.brandList.length}',
            ),
            const Divider(height: 1),
            _summaryRow(
              Icons.inventory_2_outlined,
              'Articles',
              '${settings.articleList.length}',
            ),
            const Divider(height: 1),
            _summaryRow(
              Icons.color_lens_outlined,
              'Colors',
              '${settings.colorList.length}',
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      const _SectionHeader('DANGEROUS ACTIONS'),
      Card(
        color: ColorPalette.error.withValues(alpha: 0.06),
        child: ListTile(
          leading: const Icon(Icons.restart_alt, color: ColorPalette.error),
          title: const Text('Reset settings to defaults'),
          subtitle: const Text(
            'Restores app preferences and all business settings defaults.',
          ),
          trailing: const Icon(Icons.chevron_right, color: ColorPalette.error),
          onTap: _confirmReset,
        ),
      ),
    ],
  );

  Widget _summaryRow(IconData icon, String label, String value) => ListTile(
    dense: true,
    leading: Icon(icon, color: ColorPalette.primary),
    title: Text(label),
    trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
  );

  Future<void> _copyBackup(BusinessSettingsEntity settings) async {
    final backup = <String, dynamic>{
      'type': 'footwear_business_settings_backup',
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'settings': settings.toJson(),
    };
    await Clipboard.setData(
      ClipboardData(text: const JsonEncoder.withIndent('  ').convert(backup)),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Business settings backup copied to clipboard.'),
      ),
    );
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset all settings?'),
        content: const Text(
          'This will restore app preferences and business settings to their defaults. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ColorPalette.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset settings'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    context.read<SettingsBloc>().add(const ResetToDefaults());
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

class _AdminOnlyMessage extends StatelessWidget {
  const _AdminOnlyMessage();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'Only administrators can manage settings data.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}
