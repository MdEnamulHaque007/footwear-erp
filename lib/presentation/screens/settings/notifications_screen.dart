/// ============================================================================
/// ফাইল: lib/presentation/screens/settings/notifications_screen.dart
/// স্তর: Presentation Screen | মডিউল: Settings
/// উদ্দেশ্য: Settings মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: NotificationsScreen, _NotificationsScreenState, _NotificationsContent
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

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
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
      title: const Text('Notifications'),
    ),
    body: BlocConsumer<SettingsBloc, SettingsState>(
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
        if (state is SettingsError) {
          return Center(
            child: FilledButton.icon(
              onPressed: () =>
                  context.read<SettingsBloc>().add(const LoadAppSettings()),
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          );
        }
        if (state is! AppSettingsLoaded) return const SizedBox.shrink();
        return _NotificationsContent(settings: state.entity);
      },
    ),
  );
}

class _NotificationsContent extends StatelessWidget {
  const _NotificationsContent({required this.settings});

  final AppSettingsEntity settings;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
    children: [
      Text(
        'NOTIFICATION PREFERENCES',
        style: const TextStyle(
          color: ColorPalette.muted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 8),
      Card(
        child: Column(
          children: [
            _toggle(
              icon: Icons.email_outlined,
              title: 'Email notifications',
              subtitle: 'Receive important updates by email.',
              value: settings.emailNotifications,
              onChanged: (value) => _update(
                context,
                email: value,
                push: settings.pushNotifications,
                inApp: settings.inAppNotifications,
                sound: settings.soundAlerts,
              ),
            ),
            const Divider(height: 1),
            _toggle(
              icon: Icons.notifications_outlined,
              title: 'Push notifications',
              subtitle: 'Receive notifications on this device.',
              value: settings.pushNotifications,
              onChanged: (value) => _update(
                context,
                email: settings.emailNotifications,
                push: value,
                inApp: settings.inAppNotifications,
                sound: settings.soundAlerts,
              ),
            ),
            const Divider(height: 1),
            _toggle(
              icon: Icons.message_outlined,
              title: 'In-app notifications',
              subtitle: 'Show notification messages while using the app.',
              value: settings.inAppNotifications,
              onChanged: (value) => _update(
                context,
                email: settings.emailNotifications,
                push: settings.pushNotifications,
                inApp: value,
                sound: settings.soundAlerts,
              ),
            ),
            const Divider(height: 1),
            _toggle(
              icon: Icons.volume_up_outlined,
              title: 'Sound alerts',
              subtitle: 'Play a sound for new alerts.',
              value: settings.soundAlerts,
              onChanged: (value) => _update(
                context,
                email: settings.emailNotifications,
                push: settings.pushNotifications,
                inApp: settings.inAppNotifications,
                sound: value,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _toggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => SwitchListTile.adaptive(
    secondary: Icon(icon, color: ColorPalette.primary),
    title: Text(title),
    subtitle: Text(subtitle),
    value: value,
    onChanged: onChanged,
  );

  void _update(
    BuildContext context, {
    required bool email,
    required bool push,
    required bool inApp,
    required bool sound,
  }) {
    context.read<SettingsBloc>().add(
      UpdateNotifications(email: email, push: push, inApp: inApp, sound: sound),
    );
  }
}
