import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/color_palette.dart';
import '../../domain/entities/user_entity.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';
import '../routes/route_constants.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is Authenticated ? authState.user : null;
    final isAdmin = user?.role.toLowerCase() == AppConstants.roleAdmin;

    return Drawer(
      width: 312,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _UserHeader(user: user),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                children: [
                  _section(context, 'MAIN', [
                    _item(
                      context,
                      '📊 Dashboard',
                      Icons.dashboard,
                      '/dashboard',
                    ),
                    _item(context, '📄 Master LC', Icons.article, '/master-lc'),
                    _item(
                      context,
                      '🛒 Purchase Order',
                      Icons.shopping_cart,
                      '/purchase-orders',
                    ),
                  ]),
                  _section(context, 'PRODUCTION', [
                    _item(context, '✂️ Cutting', Icons.content_cut, '/cutting'),
                    _item(context, '🧵 Sewing', Icons.weekend, '/sewing'),
                    _item(
                      context,
                      '🏭 Production',
                      Icons.factory,
                      '/production',
                    ),
                    _item(context, '📦 Issue', Icons.inventory_2, '/issue'),
                    _item(
                      context,
                      '🚢 Export',
                      Icons.local_shipping,
                      '/export',
                    ),
                  ]),
                  if (isAdmin)
                    _section(context, 'ADMIN', [
                      _item(
                        context,
                        'User Management',
                        Icons.people,
                        '/admin/users',
                      ),
                      _item(
                        context,
                        'Role Management',
                        Icons.admin_panel_settings,
                        '/admin/roles',
                      ),
                      _item(
                        context,
                        'Permission Matrix',
                        Icons.security,
                        '/admin/permissions',
                      ),
                    ]),
                  _section(context, 'REPORTS & ANALYTICS', [
                    _item(context, 'Reports', Icons.bar_chart, '/reports'),
                    _item(
                      context,
                      'Production Warehouse Report',
                      Icons.warehouse_outlined,
                      RouteConstants.warehouseReport,
                    ),
                    if (isAdmin)
                      _item(context, 'Audit Log', Icons.history, '/audit-log'),
                  ]),
                  _section(context, 'SETTINGS', [
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text('Settings'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go(RouteConstants.settings);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.help),
                      title: const Text('Help'),
                      onTap: () => _showUnavailable(context, 'Help'),
                    ),
                  ]),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () => _confirmLogout(context),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Version ${AppConstants.appVersion}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 18, 12, 6),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: ColorPalette.muted,
              letterSpacing: 0.8,
            ),
          ),
        ),
        ...items,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _item(
    BuildContext context,
    String title,
    IconData icon,
    String route,
  ) {
    final currentPath = GoRouterState.of(context).uri.path;
    final selected = currentPath == route || currentPath.startsWith('$route/');
    return ListTile(
      selected: selected,
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
      leading: Icon(icon, size: 21),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        context.go(route);
      },
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      Navigator.pop(context);
      context.read<AuthBloc>().add(LogoutRequested());
    }
  }

  void _showUnavailable(BuildContext context, String feature) {
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature is not available yet.')));
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.user});
  final UserEntity? user;

  @override
  Widget build(BuildContext context) {
    final name = user?.displayName ?? 'User';
    final email = user?.email ?? '';
    final role = user?.role.isEmpty == false ? user!.role : 'viewer';
    final initial = name.trim().isEmpty ? 'U' : name.trim()[0].toUpperCase();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF155EEF), Color(0xFF4938C2)],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white.withValues(alpha: 0.92),
            foregroundColor: ColorPalette.primary,
            child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (email.isNotEmpty)
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  Text(
                    'Role: ${role[0].toUpperCase()}${role.substring(1)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
