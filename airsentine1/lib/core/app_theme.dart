import 'package:flutter/material.dart';

final appColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF0F9D58),
  brightness: Brightness.light,
);

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: appColorScheme,
    scaffoldBackgroundColor: const Color(0xFFF5F7FA),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: appColorScheme.onSurface),
      titleTextStyle: TextStyle(
        color: appColorScheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF4F7F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
