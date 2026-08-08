import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_bottom_nav.dart';
import 'app_navigation_rail.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget child;

  const ResponsiveScaffold({
    super.key,
    required this.child,
  });

  static const _locations = <String>[
    '/',
    '/map',
    '/reports',
    '/history',
    '/settings',
  ];

  int _selectedIndex(String location) {
    if (location.startsWith('/map')) return 1;
    if (location.startsWith('/reports')) return 2;
    if (location.startsWith('/history')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _selectedIndex(location);
    final desktop = MediaQuery.of(context).size.width >= 900;

    if (desktop) {
      return Scaffold(
        body: Row(
          children: [
            AppNavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => context.go(_locations[index]),
            ),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: AppBottomNav(
        selectedIndex: selectedIndex,
        onTap: (index) => context.go(_locations[index]),
      ),
    );
  }
}
