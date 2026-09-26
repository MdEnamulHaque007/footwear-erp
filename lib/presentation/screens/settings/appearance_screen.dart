/// ============================================================================
/// ফাইল: lib/presentation/screens/settings/appearance_screen.dart
/// স্তর: Presentation Screen | মডিউল: Settings
/// উদ্দেশ্য: Settings মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: AppearanceScreen, _AppearanceScreenState, _AppearanceContent
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/color_palette.dart';
import '../../../domain/entities/settings/app_settings_entity.dart';
import '../../blocs/settings/settings_bloc.dart';
import '../../blocs/settings/settings_event.dart';
import '../../blocs/settings/settings_state.dart';
import '../../widgets/app_drawer.dart';

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SettingsBloc>().add(const LoadAppSettings());
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
            onPressed: () => context.canPop() ? context.pop() : context.go('/settings'),
          ),
          Builder(
            builder: (context) => IconButton(
              tooltip: 'Menu',
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ],
      ),
      title: const Text('Appearance'),
    ),
    body: BlocConsumer<SettingsBloc, SettingsState>(
      listener: (context, state) {
        if (state is SettingsSaved || state is SettingsError) {
          final message = state is SettingsSaved
              ? state.message
              : (state as SettingsError).message;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      builder: (context, state) {
        if (state is SettingsLoading || state is SettingsInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is SettingsError) {
          return Center(
            child: FilledButton.icon(
              onPressed: () => context.read<SettingsBloc>().add(const LoadAppSettings()),
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          );
        }
        if (state is! AppSettingsLoaded) return const SizedBox.shrink();
        return _AppearanceContent(settings: state.entity);
      },
    ),
  );
}

class _AppearanceContent extends StatelessWidget {
  const _AppearanceContent({required this.settings});

  final AppSettingsEntity settings;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
    children: [
      _sectionHeader('THEME'),
      _settingsCard(
        _radioGroup<String>(
          options: const [
            MapEntry('Light', 'light'),
            MapEntry('Dark', 'dark'),
            MapEntry('System default', 'system'),
          ],
          currentValue: settings.themeMode,
          onChanged: (value) {
            if (value != null) context.read<SettingsBloc>().add(UpdateTheme(value));
          },
        ),
      ),
      const SizedBox(height: 20),
      _sectionHeader('LANGUAGE'),
      _settingsCard(
        _radioGroup<String>(
          options: const [
            MapEntry('English', 'en'),
            MapEntry('বাংলা', 'bn'),
            MapEntry('中文', 'zh'),
          ],
          currentValue: settings.languageCode,
          onChanged: (value) {
            if (value != null) context.read<SettingsBloc>().add(UpdateLanguage(value));
          },
        ),
      ),
      const SizedBox(height: 20),
      _sectionHeader('FONT SIZE'),
      _settingsCard(
        _radioGroup<String>(
          options: const [
            MapEntry('Small', 'small'),
            MapEntry('Medium', 'medium'),
            MapEntry('Large', 'large'),
          ],
          currentValue: settings.fontSize,
          onChanged: (value) {
            if (value != null) context.read<SettingsBloc>().add(UpdateFontSize(value));
          },
        ),
      ),
      const SizedBox(height: 20),
      _sectionHeader('PREVIEW'),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Footwear ERP System\nManage your operations with clarity.',
            style: TextStyle(fontSize: _fontSize(settings.fontSize), height: 1.5, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    ],
  );

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(title, style: const TextStyle(color: ColorPalette.muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
  );

  Widget _settingsCard(Widget child) => Card(child: child);

  Widget _radioGroup<T>({
    required List<MapEntry<String, T>> options,
    required T? currentValue,
    required ValueChanged<T?> onChanged,
  }) => RadioGroup<T>(
    groupValue: currentValue,
    onChanged: onChanged,
    child: Column(
      children: options
          .map(
            (option) => RadioListTile<T>(
              title: Text(option.key),
              value: option.value,
            ),
          )
          .toList(),
    ),
  );

  double _fontSize(String value) => switch (value) {
    'small' => 14,
    'large' => 20,
    _ => 16,
  };
}
