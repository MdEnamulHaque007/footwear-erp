import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'route_constants.dart';

/// Keeps a direct route home available, including on deep-linked pages.
class HomeNavigationShell extends StatelessWidget {
  const HomeNavigationShell({
    super.key,
    required this.location,
    required this.child,
  });

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (location == RouteConstants.dashboard ||
        location == RouteConstants.login ||
        location == RouteConstants.register ||
        location == RouteConstants.resetPassword) {
      return child;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextButton.icon(
            onPressed: () => context.go(RouteConstants.dashboard),
            icon: const Icon(Icons.home_outlined),
            label: const Text('Home'),
          ),
        ),
      ),
    );
  }
}
