import 'package:flutter/material.dart';

import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/history/presentation/history_page.dart';
import '../../features/map/presentation/map_page.dart';
import '../../features/reports/presentation/reports_page.dart';
import '../../features/settings/presentation/settings_page.dart';

import 'app_bottom_nav.dart';
import 'app_navigation_rail.dart';

class ResponsiveScaffold extends StatefulWidget {
  const ResponsiveScaffold({super.key});

  @override
  State<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold> {
  int selectedIndex = 0;

  final pages = const [
    DashboardPage(),
    MapPage(),
    ReportsPage(),
    HistoryPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.of(context).size.width >= 900;

    if (desktop) {
      return Scaffold(
        body: Row(
          children: [
            AppNavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (i) {
                setState(() => selectedIndex = i);
              },
            ),
            Expanded(child: pages[selectedIndex]),
          ],
        ),
      );
    }

    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: AppBottomNav(
        selectedIndex: selectedIndex,
        onTap: (i) {
          setState(() => selectedIndex = i);
        },
      ),
    );
  }
}