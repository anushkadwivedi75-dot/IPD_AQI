import 'package:airsentine1/app/router.dart';
import 'package:airsentine1/core/app_theme.dart';
import 'package:flutter/material.dart';

class AirSentinelApp extends StatelessWidget {
  const AirSentinelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AirSentinel',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: appRouter,
    );
  }
}