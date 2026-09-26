/// ============================================================================
/// ফাইল: lib/presentation/screens/settings/settings_screen.dart
/// স্তর: Presentation Screen | মডিউল: Settings
/// উদ্দেশ্য: Settings মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: SettingsScreen, _SettingsScreenState
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/color_palette.dart';
import '../../../domain/entities/user_entity.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/settings/settings_bloc.dart';
import '../../blocs/settings/settings_event.dart';
import '../../blocs/settings/settings_state.dart';
import '../../routes/route_constants.dart';
import '../../widgets/app_drawer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SettingsBloc>()
        ..add(const LoadAppSettings())
        ..add(const LoadBusinessSettings());
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leadingWidth: 96,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(RouteConstants.dashboard),
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
      title: const Text('Settings'),
    ),
    drawer: const AppDrawer(),
    body: BlocListener<SettingsBloc, SettingsState>(
      listener: (context, state) {
        if (state is SettingsError || state is SettingsSaved) {
          final message = state is SettingsError
              ? state.message
              : (state as SettingsSaved).message;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final user = authState is Authenticated ? authState.user : null;
          final isAdmin = user?.role == 'admin';
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              if (user != null) _profileCard(user),
              if (user != null) const SizedBox(height: 24),
              _sectionHeader('APPEARANCE'),
              _settingsCard([
                _listTile(Icons.palette_outlined, 'Theme', route: '/settings/appearance'),
                _listTile(Icons.language_outlined, 'Language', route: '/settings/appearance'),
                _listTile(Icons.text_fields_outlined, 'Font Size', route: '/settings/appearance'),
              ]),
              const SizedBox(height: 20),
              _sectionHeader('NOTIFICATIONS'),
              _settingsCard([_listTile(Icons.notifications_outlined, 'Notifications', route: '/settings/notifications')]),
              if (isAdmin) ...[
                const SizedBox(height: 20),
                _sectionHeader('BUSINESS SETTINGS'),
                _settingsCard([
                  _listTile(Icons.business_outlined, 'Company Info', route: '/settings/business'),
                  _listTile(Icons.factory_outlined, 'Factory List', route: '/settings/factory'),
                  _listTile(Icons.folder_outlined, 'Project List', route: '/settings/project'),
                  _listTile(Icons.sell_outlined, 'Brand List', route: '/settings/brand'),
                  _listTile(Icons.inventory_2_outlined, 'Article Master', route: '/settings/article'),
                  _listTile(Icons.color_lens_outlined, 'Color Master', route: '/settings/color'),
                ]),
                const SizedBox(height: 20),
                _sectionHeader('USER MANAGEMENT'),
                _settingsCard([
                  _listTile(Icons.people_outline, 'User List', route: '/admin/users'),
                  _listTile(Icons.admin_panel_settings_outlined, 'Role Management', route: '/admin/roles'),
                  _listTile(Icons.security_outlined, 'Permission Matrix', route: '/admin/permissions'),
                ]),
                const SizedBox(height: 20),
                _sectionHeader('DATA MANAGEMENT'),
                _settingsCard([_listTile(Icons.storage_outlined, 'Data Management', route: '/settings/data')]),
              ],
              const SizedBox(height: 20),
              _sectionHeader('SECURITY'),
              _settingsCard([_listTile(Icons.shield_outlined, 'Security', route: '/settings/security')]),
              const SizedBox(height: 20),
              _sectionHeader('APP'),
              _settingsCard([
                _listTile(Icons.info_outline, 'Version Info', subtitle: 'v1.0.0'),
                _listTile(Icons.description_outlined, 'Terms & Conditions', onTap: () => _showInfoDialog(context, 'Terms & Conditions')),
                _listTile(Icons.privacy_tip_outlined, 'Privacy Policy', onTap: () => _showInfoDialog(context, 'Privacy Policy')),
                _listTile(Icons.support_agent_outlined, 'Contact Support', onTap: () => _showInfoDialog(context, 'Contact Support')),
              ]),
              const SizedBox(height: 20),
              _sectionHeader('ABOUT'),
              _settingsCard([_listTile(Icons.info_outline, 'About Us', route: '/settings/about')]),
              const Divider(height: 40),
              _settingsCard([
                _listTile(Icons.logout, 'Logout', iconColor: ColorPalette.error, textColor: ColorPalette.error, onTap: () => _showLogoutDialog(context)),
              ]),
            ],
          );
        },
      ),
    ),
  );

  Widget _profileCard(UserEntity user) {
    final name = user.displayName.trim().isEmpty ? 'User' : user.displayName;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => context.push('/settings/profile'),
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(colors: [ColorPalette.primary, Color(0xFF4938C2)]),
        ),
        child: Row(
          children: [
            CircleAvatar(radius: 28, backgroundColor: Colors.white.withValues(alpha: 0.92), foregroundColor: ColorPalette.primary, child: Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 3),
              Text(user.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.82))),
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(20)), child: Text(user.role.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.7))),
            ])),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(title, style: const TextStyle(color: ColorPalette.muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
  );

  Widget _settingsCard(List<Widget> children) => Card(child: Column(children: children));

  Widget _listTile(IconData icon, String title, {String? subtitle, String? route, Color? iconColor, Color? textColor, VoidCallback? onTap}) => ListTile(
    leading: Icon(icon, color: iconColor ?? ColorPalette.primary),
    title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
    subtitle: subtitle == null ? null : Text(subtitle),
    trailing: Icon(Icons.chevron_right_rounded, color: textColor ?? ColorPalette.muted),
    onTap: onTap ?? (route == null ? null : () => context.push(route)),
  );

  Future<void> _showInfoDialog(BuildContext context, String title) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(title: Text(title), content: const Text('This information will be available soon.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]),
  );

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(backgroundColor: ColorPalette.error), child: const Text('Logout')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AuthBloc>().add(LogoutRequested());
    }
  }
}
