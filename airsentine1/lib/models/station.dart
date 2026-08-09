import 'package:airsentine1/core/aqi_utils.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

export 'package:airsentine1/core/aqi_utils.dart';

/// Legacy enum export / alias for backward compatibility
typedef AqiCategory = CpcbAqiCategory;

/// Individual Pollutant model according to CPCB standards
class PollutantDetail {
  final String code;
  final String name;
  final double value;
  final String unit; // 'µg/m³' or 'mg/m³' (CO)
  final int? subIndex; // CPCB Sub-index value (AQI = max of sub-indices)
  final String trend;
  final String description;

  const PollutantDetail({
    required this.code,
    required this.name,
    required this.value,
    required this.unit,
    this.subIndex,
    required this.trend,
    required this.description,
  });
}

/// Type alias for backward compatibility
typedef Pollutant = PollutantDetail;

/// Weather Information model (Celsius, km/h, IST, UV index)
class WeatherInfo {
  final double temperatureC;
  final int humidity;
  final double windKph;
  final String condition;
  final String sunrise;
  final String sunset;
  final int uvIndex;

  const WeatherInfo({
    required this.temperatureC,
    required this.humidity,
    required this.windKph,
    required this.condition,
    required this.sunrise,
    required this.sunset,
    this.uvIndex = 6,
  });
}

/// Type alias for backward compatibility
typedef WeatherSummary = WeatherInfo;

/// Daily Forecast entry model (DD/MM/YYYY format)
class DailyForecast {
  final String label; // e.g. "10/08/2026" or "Today"
  final int aqi;
  final String condition;
  final int high;
  final int low;

  const DailyForecast({
    required this.label,
    required this.aqi,
    required this.condition,
    required this.high,
    required this.low,
  });
}

/// Type alias for backward compatibility
typedef ForecastEntry = DailyForecast;

/// Hourly Historical Reading model (IST timestamp HH:mm)
class HourlyReading {
  final String hour; // e.g. "06:00"
  final int aqi;

  const HourlyReading({
    required this.hour,
    required this.aqi,
  });
}

/// Type alias for backward compatibility
typedef HistoryEntry = HourlyReading;

/// Health Advice model
class HealthAdvice {
  final String title;
  final String description;
  final IconData icon;
  final Color tint;

  const HealthAdvice({
    required this.title,
    required this.description,
    required this.icon,
    required this.tint,
  });
}

/// Monitoring Station model representing an Indian air quality station
class MonitoringStation {
  final String id;
  final String name;
  final String area;
  final int aqi;
  final String primaryPollutant;
  final String summary;
  final WeatherInfo weather;
  final List<PollutantDetail> pollutants;
  final List<DailyForecast> forecast;
  final List<HourlyReading> history;
  final List<HealthAdvice> advice;
  final LatLng location;
  final bool isOutdoor;

  const MonitoringStation({
    required this.id,
    required this.name,
    required this.area,
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

  AqiMeta get aqiMeta => getAqiMeta(aqi);
  CpcbAqiCategory get category => aqiMeta.category;
  Color get color => aqiMeta.color;
  Color get background => aqiMeta.backgroundColor;
}

/// Type alias for backward compatibility
typedef Station = MonitoringStation;
