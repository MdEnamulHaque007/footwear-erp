import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../blocs/auth/auth_bloc.dart';
import '../../../../blocs/auth/auth_state.dart';
import '../../../../routes/route_constants.dart';
import 'date_range_selector.dart';
import 'project_selector.dart';

class DashboardTopbar extends StatelessWidget {
  const DashboardTopbar({super.key, required this.onMenu});
  final VoidCallback onMenu;
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final user = state is Authenticated ? state.user : null;
    final name = user?.displayLabel ?? 'User';
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 650;
      return Material(color: Colors.white, child: Container(
        height: 64, padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE1E8ED)))),
        child: Row(children: [
          IconButton(onPressed: onMenu, icon: const Icon(Icons.menu), tooltip: 'Menu'),
          if (compact) const Expanded(child: Text('Production Dashboard', overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700))) else const Expanded(child: ProjectSelector()),
          if (!compact) ...[const SizedBox(width: 12), const DateRangeSelector()],
          IconButton(onPressed: () => context.go(RouteConstants.settings), icon: const Icon(Icons.settings_outlined), tooltip: 'Settings'),
          Badge(child: IconButton(onPressed: () => context.push('/settings/notifications'), icon: const Icon(Icons.notifications_none), tooltip: 'Notifications')),
          CircleAvatar(radius: 17, child: Text(name.isEmpty ? 'U' : name.substring(0, 1).toUpperCase())),
          if (!compact) ...[const SizedBox(width: 8), Flexible(child: Text(name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)))],
        ]),
      ));
    });
  }
}
