import 'package:flutter/material.dart';

/// Global Design Tokens for AirSentinel
class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;

  static const BorderRadius smBorder = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdBorder = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgBorder = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlBorder = BorderRadius.all(Radius.circular(xl));
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> cardElevated = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
}

class AppGradients {
  static const LinearGradient darkAccent = LinearGradient(
    colors: [
      Color(0xFF1E293B),
      Color(0xFF0F172A),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [
      Color(0xFF0F172A),
      Color(0xFF1E1E38),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppTypography {
  static const TextStyle aqiNumber = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.0,
    height: 1.0,
  );

  static const TextStyle cardHeader = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  static const TextStyle metadata = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Color(0xFF64748B),
  );

  static const TextStyle badgeText = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );
}
