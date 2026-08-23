import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: GridView.count(
        padding: const EdgeInsets.all(24),
        crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _module(context, 'Master LC', '/master-lc', Icons.description),
          _module(
            context,
            'Purchase Orders',
            '/purchase-orders',
            Icons.shopping_cart,
          ),
          _module(context, 'Cutting', '/cutting', Icons.content_cut),
          _module(context, 'Sewing', '/sewing', Icons.checkroom),
          _module(context, 'Production', '/production', Icons.factory),
          _module(context, 'Issue', '/issue', Icons.outbox),
          _module(context, 'Export', '/export', Icons.local_shipping),
        ],
      ),
    );
  }

  Widget _module(
    BuildContext context,
    String title,
    String route,
    IconData icon,
  ) {
    return Card(
      child: InkWell(
        onTap: () {
          debugPrint('Navigating to $title');
          context.go(route);
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 30),
              const Spacer(),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
