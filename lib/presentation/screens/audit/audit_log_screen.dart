import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/color_palette.dart';
import '../../routes/route_constants.dart';
import '../../widgets/empty_state.dart';

/// Placeholder for the Audit Log module so the drawer's "Audit Log" link
/// resolves instead of falling through to the "Page not found" error builder.
///
/// Access is restricted to admins: [RouteGuard] redirects non-admin users to
/// `/unauthorized` (see `route_guard.dart`).
class AuditLogScreen extends StatelessWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Log'),
        backgroundColor: ColorPalette.auditLog,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Dashboard',
          onPressed: () => context.go(RouteConstants.dashboard),
        ),
      ),
      body: EmptyState(
        icon: Icons.history,
        iconColor: ColorPalette.auditLog,
        title: '📜 Audit Log Coming Soon',
        subtitle: 'Audit Log module is under development.',
        action: FilledButton.icon(
          onPressed: () => context.go(RouteConstants.dashboard),
          icon: const Icon(Icons.home_outlined),
          label: const Text('Back to Dashboard'),
        ),
      ),
    );
  }
}
