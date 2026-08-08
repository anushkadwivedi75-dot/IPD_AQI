import 'package:airsentine1/app/navigation/responsive_scaffold.dart';
import 'package:airsentine1/features/dashboard/presentation/dashboard_page.dart';
import 'package:airsentine1/features/history/presentation/history_page.dart';
import 'package:airsentine1/features/map/presentation/map_page.dart';
import 'package:airsentine1/features/reports/presentation/reports_page.dart';
import 'package:airsentine1/features/settings/presentation/settings_page.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => ResponsiveScaffold(child: child),
      routes: [
        GoRoute(
          name: 'dashboard',
          path: '/',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          name: 'map',
          path: '/map',
          builder: (context, state) => const MapPage(),
        ),
        GoRoute(
          name: 'reports',
          path: '/reports',
          builder: (context, state) => const ReportsPage(),
        ),
        GoRoute(
          name: 'history',
          path: '/history',
          builder: (context, state) => const HistoryPage(),
        ),
        GoRoute(
          name: 'settings',
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),
      ],
    ),
  ],
);
