import 'package:flutter/material.dart';
import 'package:airsentine1/app/navigation/responsive_scaffold.dart';
import 'package:airsentine1/features/ai_assistant/presentation/ai_assistant_page.dart';
import 'package:airsentine1/features/dashboard/presentation/dashboard_page.dart';
import 'package:airsentine1/features/history/presentation/history_page.dart';
import 'package:airsentine1/features/map/presentation/map_page.dart';
import 'package:airsentine1/features/reports/presentation/reports_page.dart';
import 'package:airsentine1/features/settings/presentation/settings_page.dart';
import 'package:airsentine1/features/station_detail/presentation/station_detail_page.dart';
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
          name: 'dashboard-alt',
          path: '/dashboard',
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
    // Modal routes
    GoRoute(
      name: 'station-detail',
      path: '/station/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? 'station-delhi-anand-vihar';
        return StationDetailPage(stationId: id);
      },
    ),
    GoRoute(
      name: 'ai-assistant',
      path: '/ai-assistant',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          opaque: false,
          barrierDismissible: true,
          barrierColor: Colors.black.withValues(alpha: 0.55),
          transitionDuration: const Duration(milliseconds: 250),
          child: const AiAssistantPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.94, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                ),
                child: child,
              ),
            );
          },
        );
      },
    ),
  ],
);
