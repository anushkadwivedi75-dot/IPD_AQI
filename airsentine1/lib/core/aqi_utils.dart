import 'package:flutter/material.dart';

/// CPCB National Air Quality Index Categories
enum CpcbAqiCategory {
  good,
  satisfactory,
  moderate,
  poor,
  veryPoor,
  severe,
}

/// Type alias for backward compatibility or alternative naming
typedef AqiRiskCategory = CpcbAqiCategory;

/// Single-source-of-truth metadata model for AQI styling and health advisories.
class AqiMeta {
  final CpcbAqiCategory category;
  final String label;
  final Color color;
  final Color backgroundColor;
  final Color badgeTextColor;
  final Color dotColor;
  final double gaugePercent;
  final String healthAdvisory;

  const AqiMeta({
    required this.category,
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.badgeTextColor,
    required this.dotColor,
    required this.gaugePercent,
    required this.healthAdvisory,
  });
}

/// Single-source-of-truth CPCB AQI metadata generator.
/// Range: 0–500 scale according to India CPCB standard.
AqiMeta getAqiMeta(int rawAqi) {
  final int aqi = rawAqi.clamp(0, 999);
  final double gaugePercent = ((aqi / 500.0) * 100.0).clamp(0.0, 100.0);

  if (aqi <= 50) {
    return AqiMeta(
      category: CpcbAqiCategory.good,
      label: 'Good',
      color: const Color(0xFF00B050),
      backgroundColor: const Color(0xFFE8F5E9),
      badgeTextColor: const Color(0xFF1B5E20),
      dotColor: const Color(0xFF00B050),
      gaugePercent: gaugePercent,
      healthAdvisory: 'Minimal impact on health. Air quality is considered satisfactory and poses little or no risk.',
    );
  } else if (aqi <= 100) {
    return AqiMeta(
      category: CpcbAqiCategory.satisfactory,
      label: 'Satisfactory',
      color: const Color(0xFF7CB342),
      backgroundColor: const Color(0xFFF1F8E9),
      badgeTextColor: const Color(0xFF33691E),
      dotColor: const Color(0xFF7CB342),
      gaugePercent: gaugePercent,
      healthAdvisory: 'Minor breathing discomfort to sensitive people. Enjoy normal outdoor activities.',
    );
  } else if (aqi <= 200) {
    return AqiMeta(
      category: CpcbAqiCategory.moderate,
      label: 'Moderate',
      color: const Color(0xFFFBC02D),
      backgroundColor: const Color(0xFFFFFDE7),
      badgeTextColor: const Color(0xFFF57F17),
      dotColor: const Color(0xFFFBC02D),
      gaugePercent: gaugePercent,
      healthAdvisory: 'Breathing discomfort to people with lungs, asthma and heart diseases on prolonged exposure.',
    );
  } else if (aqi <= 300) {
    return AqiMeta(
      category: CpcbAqiCategory.poor,
      label: 'Poor',
      color: const Color(0xFFF57C00),
      backgroundColor: const Color(0xFFFFF3E0),
      badgeTextColor: const Color(0xFFE65100),
      dotColor: const Color(0xFFF57C00),
      gaugePercent: gaugePercent,
      healthAdvisory: 'Breathing discomfort to most people on prolonged exposure. Limit outdoor exertion.',
    );
  } else if (aqi <= 400) {
    return AqiMeta(
      category: CpcbAqiCategory.veryPoor,
      label: 'Very Poor',
      color: const Color(0xFFD32F2F),
      backgroundColor: const Color(0xFFFFEBEE),
      badgeTextColor: const Color(0xFFB71C1C),
      dotColor: const Color(0xFFD32F2F),
      gaugePercent: gaugePercent,
      healthAdvisory: 'Respiratory illness on prolonged exposure. Avoid outdoor activities.',
    );
  } else {
    return AqiMeta(
      category: CpcbAqiCategory.severe,
      label: 'Severe',
      color: const Color(0xFF70131B),
      backgroundColor: const Color(0xFFFCE4EC),
      badgeTextColor: const Color(0xFF4A0007),
      dotColor: const Color(0xFF70131B),
      gaugePercent: gaugePercent,
      healthAdvisory: 'Severe: avoid all outdoor activity; sensitive groups should stay indoors. Seriously impacts healthy people.',
    );
  }
}
