import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../blocs/auth/auth_bloc.dart';
import '../../../../blocs/auth/auth_event.dart';
import '../../../../blocs/auth/auth_state.dart';
import '../../../../routes/route_constants.dart';

class SidebarUserProfile extends StatelessWidget {
  const SidebarUserProfile({super.key, required this.compact});
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final user = state is Authenticated ? state.user : null;
    final name = user?.displayLabel ?? 'User';
    return Padding(padding: const EdgeInsets.all(10), child: Material(
      color: const Color(0xFF26364A), borderRadius: BorderRadius.circular(12),
      child: InkWell(onTap: () => context.go(RouteConstants.profile), borderRadius: BorderRadius.circular(12), child: Padding(
        padding: const EdgeInsets.all(10), child: Row(children: [
          CircleAvatar(child: Text(name.isEmpty ? 'U' : name.substring(0, 1).toUpperCase())),
          if (!compact) ...[
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              Text(user?.role ?? 'viewer', style: const TextStyle(color: Color(0xFFB8C4D3), fontSize: 12)),
            ])),
            PopupMenuButton<String>(iconColor: Colors.white, onSelected: (value) {
              if (value == 'logout') {
                context.read<AuthBloc>().add(LogoutRequested());
              }
            }, itemBuilder: (_) => const [PopupMenuItem(value: 'logout', child: Text('Logout'))]),
          ],
        ]),
      )),
    ));
  }
}
