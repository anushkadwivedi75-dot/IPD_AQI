import 'package:flutter/material.dart';

/// Accessible Bottom Navigation Bar with clear active-state styling and tooltips
class AppBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Main Navigation Bar',
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onTap,
        elevation: 8,
        indicatorColor: const Color(0xFFE8F5E9),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Color(0xFF0F9D58)),
            label: 'Dashboard',
            tooltip: 'Navigate to Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: Color(0xFF0F9D58)),
            label: 'Map',
            tooltip: 'Navigate to Interactive AQI Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.assessment_outlined),
            selectedIcon: Icon(Icons.assessment, color: Color(0xFF0F9D58)),
            label: 'Reports',
            tooltip: 'Navigate to AQI Reports & Forecasts',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart, color: Color(0xFF0F9D58)),
            label: 'History',
            tooltip: 'Navigate to 24-Hour AQI History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: Color(0xFF0F9D58)),
            label: 'Settings',
            tooltip: 'Navigate to App Settings',
          ),
        ],
      ),
    );
  }
}