import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum AqiCategory {
  good,
  moderate,
  unhealthySensitive,
  unhealthy,
  veryUnhealthy,
  hazardous,
}

extension AqiCategoryProperties on AqiCategory {
  String get label {
    switch (this) {
      case AqiCategory.good:
        return 'Good';
      case AqiCategory.moderate:
        return 'Moderate';
      case AqiCategory.unhealthySensitive:
        return 'Unhealthy for Sensitive Groups';
      case AqiCategory.unhealthy:
        return 'Unhealthy';
      case AqiCategory.veryUnhealthy:
        return 'Very Unhealthy';
      case AqiCategory.hazardous:
        return 'Hazardous';
    }
  }

  Color get color {
    switch (this) {
      case AqiCategory.good:
        return const Color(0xFF2D8A4A);
      case AqiCategory.moderate:
        return const Color(0xFFECA400);
      case AqiCategory.unhealthySensitive:
        return const Color(0xFFF08C00);
      case AqiCategory.unhealthy:
        return const Color(0xFFE65100);
      case AqiCategory.veryUnhealthy:
        return const Color(0xFFC62147);
      case AqiCategory.hazardous:
        return const Color(0xFF7C1E61);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case AqiCategory.good:
        return const Color(0xFFE8F6EB);
      case AqiCategory.moderate:
        return const Color(0xFFFFF4D2);
      case AqiCategory.unhealthySensitive:
        return const Color(0xFFFFE7C1);
      case AqiCategory.unhealthy:
        return const Color(0xFFFFE3D1);
      case AqiCategory.veryUnhealthy:
        return const Color(0xFFF8D3DE);
      case AqiCategory.hazardous:
        return const Color(0xFFF3D7E4);
    }
  }
}

class Pollutant {
  final String code;
  final String name;
  final double value;
  final String unit;
  final String trend;
  final String description;

  Pollutant({
    required this.code,
    required this.name,
    required this.value,
    required this.unit,
    required this.trend,
    required this.description,
  });
}

class WeatherSummary {
  final double temperatureC;
  final int humidity;
  final double windKph;
  final String condition;
  final String sunrise;
  final String sunset;

  WeatherSummary({
    required this.temperatureC,
    required this.humidity,
    required this.windKph,
    required this.condition,
    required this.sunrise,
    required this.sunset,
  });
}

class ForecastEntry {
  final String label;
  final int aqi;
  final String condition;
  final int high;
  final int low;

  ForecastEntry({
    required this.label,
    required this.aqi,
    required this.condition,
    required this.high,
    required this.low,
  });
}

class HistoryEntry {
  final String hour;
  final int aqi;

  HistoryEntry({
    required this.hour,
    required this.aqi,
  });
}

class HealthAdvice {
  final String title;
  final String description;
  final IconData icon;
  final Color tint;

  HealthAdvice({
    required this.title,
    required this.description,
    required this.icon,
    required this.tint,
  });
}

class Station {
  final String id;
  final String name;
  final String area;
  final AqiCategory category;
  final int aqi;
  final String primaryPollutant;
  final String summary;
  final WeatherSummary weather;
  final List<Pollutant> pollutants;
  final List<ForecastEntry> forecast;
  final List<HistoryEntry> history;
  final List<HealthAdvice> advice;
  final LatLng location;
  final bool isOutdoor;

  Station({
    required this.id,
    required this.name,
    required this.area,
    required this.category,
    required this.aqi,
    required this.primaryPollutant,
    required this.summary,
    required this.weather,
    required this.pollutants,
    required this.forecast,
    required this.history,
    required this.advice,
    required this.location,
    this.isOutdoor = true,
  });

  Color get color => category.color;
  Color get background => category.backgroundColor;
}
