import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminSidebarWidget extends StatelessWidget {
  const AdminSidebarWidget({super.key});
  @override
  Widget build(BuildContext context) => Drawer(
    child: ListView(
      children: [
        const DrawerHeader(child: Text('Admin Panel')),
        ListTile(
          leading: const Icon(Icons.dashboard),
          title: const Text('Overview'),
          onTap: () => context.go('/admin'),
        ),
        ListTile(
          leading: const Icon(Icons.people),
          title: const Text('Users'),
          onTap: () => context.go('/admin/users'),
        ),
        ListTile(
          leading: const Icon(Icons.badge),
          title: const Text('Roles'),
          onTap: () => context.go('/admin/roles'),
        ),
        ListTile(
          leading: const Icon(Icons.grid_on),
          title: const Text('Permissions'),
          onTap: () => context.go('/admin/permissions'),
        ),
      ],
    ),
  );
}
