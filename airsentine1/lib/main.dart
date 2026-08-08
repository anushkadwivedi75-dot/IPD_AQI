import 'package:airsentine1/app/app.dart';
import 'package:airsentine1/providers/app_state.dart';
import 'package:airsentine1/services/preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await PreferencesService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        preferencesServiceProvider.overrideWithValue(preferences),
      ],
      child: const AirSentinelApp(),
    ),
  );
}