import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'route_constants.dart';
import '../widgets/app_drawer.dart';

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
    if (location == RouteConstants.login ||
        location == RouteConstants.register ||
        location == RouteConstants.resetPassword) {
      return child;
    }

    return Scaffold(
      drawer: const AppDrawer(),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(location),
        onDestinationSelected: (index) => context.go(_destinations[index].route),
        destinations: _destinations
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }

  int _selectedIndex(String currentLocation) {
    for (var index = 0; index < _destinations.length; index++) {
      final route = _destinations[index].route;
      if (currentLocation == route ||
          (route != RouteConstants.dashboard &&
              currentLocation.startsWith('$route/'))) {
        return index;
      }
    }
    return 0;
  }
}

class _NavigationDestinationData {
  const _NavigationDestinationData(
    this.label,
    this.route,
    this.icon,
    this.selectedIcon,
  );

  final String label;
  final String route;
  final IconData icon;
  final IconData selectedIcon;
}

const _destinations = <_NavigationDestinationData>[
  _NavigationDestinationData(
    'Home',
    RouteConstants.dashboard,
    Icons.home_outlined,
    Icons.home,
  ),
  _NavigationDestinationData(
    'Report',
    RouteConstants.reports,
    Icons.bar_chart_outlined,
    Icons.bar_chart,
  ),
  _NavigationDestinationData(
    'Audit Log',
    RouteConstants.auditLog,
    Icons.history_outlined,
    Icons.history,
  ),
  _NavigationDestinationData(
    'Settings',
    RouteConstants.settings,
    Icons.settings_outlined,
    Icons.settings,
  ),
  _NavigationDestinationData(
    'Profile',
    RouteConstants.profile,
    Icons.person_outline,
    Icons.person,
  ),
];
