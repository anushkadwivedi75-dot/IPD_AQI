import 'package:flutter/material.dart';
import 'navigation/responsive_scaffold.dart';

class AirSentinelApp extends StatelessWidget {
  const AirSentinelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AirSentinel',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        scaffoldBackgroundColor: const Color(0xffF5F7FA),
      ),
      home: const ResponsiveScaffold(),
    );
  }
}