import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/color_palette.dart';
import '../../../domain/entities/user_entity.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/app_drawer.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is Authenticated ? authState.user : null;
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _welcome(context, user),
          const SizedBox(height: 20),
          Text('Quick Access', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.25,
            children: [
              _module(
                context,
                '📄 Master LC',
                '/master-lc',
                Icons.description,
                ColorPalette.masterLc,
              ),
              _module(
                context,
                '🛒 Purchase Orders',
                '/purchase-orders',
                Icons.shopping_cart,
                ColorPalette.purchaseOrder,
              ),
              _module(
                context,
                '✂️ Cutting',
                '/cutting',
                Icons.content_cut,
                ColorPalette.cutting,
              ),
              _module(
                context,
                '🧵 Sewing',
                '/sewing',
                Icons.checkroom,
                ColorPalette.sewing,
              ),
              _module(
                context,
                '🏭 Production',
                '/production',
                Icons.factory,
                ColorPalette.production,
              ),
              _module(
                context,
                '📦 Issue',
                '/issue',
                Icons.outbox,
                ColorPalette.issue,
              ),
              _module(
                context,
                '🚢 Export',
                '/export',
                Icons.local_shipping,
                ColorPalette.export,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _module(
    BuildContext context,
    String title,
    String route,
    IconData icon,
    Color color,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(route),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.14),
                foregroundColor: color,
                child: Icon(icon),
              ),
              const Spacer(),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }

  Widget _welcome(BuildContext context, UserEntity? user) {
    final today = DateTime.now();
    return Card(
      color: ColorPalette.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '👋 Hello, ${user?.displayName ?? 'User'}!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text('Role: 👑 ${user?.role ?? 'Viewer'}'),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 6),
                  Text(DateFormat('dd/MM/yyyy', 'en_US').format(today)),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 6),
                  Text(DateFormat('hh:mm:ss a', 'en_US').format(today)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
