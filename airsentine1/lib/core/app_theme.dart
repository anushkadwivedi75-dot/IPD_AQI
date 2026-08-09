import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Warm Eye-Friendly Light Color Scheme
final lightColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF0F9D58),
  brightness: Brightness.light,
  surface: const Color(0xFFFFFFFF),
  onSurface: const Color(0xFF1C1917),
  primary: const Color(0xFF0F9D58),
  secondary: const Color(0xFFD97706),
);

/// Warm Eye-Friendly Dark Color Scheme
final darkColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF10B981),
  brightness: Brightness.dark,
  surface: const Color(0xFF1E1B18),
  onSurface: const Color(0xFFF5F2EB),
  primary: const Color(0xFF10B981),
  secondary: const Color(0xFFF59E0B),
);

ThemeData buildLightTheme() {
  final base = ThemeData.light(useMaterial3: true);

  return base.copyWith(
    colorScheme: lightColorScheme,
    scaffoldBackgroundColor: const Color(0xFFFAF7F2), // Warm Cream / Soft Alabaster
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: const Color(0xFF1C1917),
      displayColor: const Color(0xFF1C1917),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFAF7F2),
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF1C1917)),
      titleTextStyle: TextStyle(
        color: Color(0xFF1C1917),
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        side: BorderSide(color: Color(0xFFEBE5DF), width: 1.0),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF2ECE4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

ThemeData buildDarkTheme() {
  final base = ThemeData.dark(useMaterial3: true);

  return base.copyWith(
    colorScheme: darkColorScheme,
    scaffoldBackgroundColor: const Color(0xFF141210), // Deep Warm Obsidian
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: const Color(0xFFF5F2EB),
      displayColor: const Color(0xFFF5F2EB),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF141210),
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: Color(0xFFF5F2EB)),
      titleTextStyle: TextStyle(
        color: Color(0xFFF5F2EB),
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF1E1B18), // Warm Charcoal Card
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        side: BorderSide(color: Color(0xFF2E2924), width: 1.0),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF28231E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
