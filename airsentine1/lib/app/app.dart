import 'package:airsentine1/app/router.dart';
import 'package:airsentine1/core/app_theme.dart';
import 'package:airsentine1/providers/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AirSentinelApp extends ConsumerWidget {
  const AirSentinelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'AIRSENTINEL',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      routerConfig: appRouter,
    );
  }
}