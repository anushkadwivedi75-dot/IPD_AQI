import 'package:airsentine1/data/sample_data.dart';
import 'package:airsentine1/models/heatmap_point.dart';
import 'package:airsentine1/models/reading.dart';
import 'package:airsentine1/models/site_history_response.dart';
import 'package:airsentine1/models/station.dart';
import 'package:airsentine1/services/api_service.dart';
import 'package:intl/intl.dart';

class AqiRepository {
  final ApiService _apiService;

  AqiRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Fetch heatmap aggregated points from backend
  Future<List<HeatmapPoint>> fetchHeatmap({
    double minLat = 18.8,
    double minLng = 72.7,
    double maxLat = 19.2,
    double maxLng = 73.0,
  }) async {
    return await _apiService.fetchHeatmap(
      minLat: minLat,
      minLng: minLng,
      maxLat: maxLat,
      maxLng: maxLng,
    );
  }

  /// Fetch site history readings from backend
  Future<SiteHistoryResponse> fetchSiteHistory(
    String siteId, {
    int hours = 24,
  }) async {
    return await _apiService.fetchSiteHistory(siteId, hours: hours);
  }

  /// Post batch readings to backend
  Future<BatchReadingResponse> postReadingsBatch(List<Reading> readings) async {
    return await _apiService.postReadingsBatch(readings);
  }

  /// Fetch monitoring stations, enriching with live API readings when available,
  /// or falling back smoothly to sample_data stations.
  Future<List<MonitoringStation>> getStations() async {
    // Start with fallback sample stations list
    final List<MonitoringStation> updatedStations = List.from(stations);

    try {
      // Known backend site IDs mapping to stations
      final siteMappings = <String, String>{
        'ad7efa75-a8bb-4b7f-917b-1314b272fa4b': 'station-mumbai-bkc',
        '3a0c762a-13ba-4b27-9b56-c24be1dba7ab': 'station-mumbai-colaba',
      };

      for (final entry in siteMappings.entries) {
        final siteId = entry.key;
        final stationId = entry.value;

        try {
          final historyResponse = await _apiService.fetchSiteHistory(siteId, hours: 24);
          if (historyResponse.readings.isNotEmpty) {
            final readings = historyResponse.readings;
            final latestReading = readings.last;
            final latestAqi = latestReading.aqi ?? 100;
            final latestPm25 = latestReading.pm25 ?? 45.0;

            final hourlyHistory = readings.map((r) {
              final dt = r.recordedAt?.toLocal() ?? DateTime.now();
              final timeStr = DateFormat('HH:mm').format(dt);
              return HourlyReading(
                hour: timeStr,
                aqi: r.aqi ?? 0,
              );
            }).toList();

            final index = updatedStations.indexWhere((s) => s.id == stationId);
            if (index != -1) {
              final orig = updatedStations[index];

              // Update pollutants with live PM2.5 & AQI
              final updatedPollutants = orig.pollutants.map((p) {
                if (p.code == 'PM2.5') {
                  return PollutantDetail(
                    code: p.code,
                    name: p.name,
                    value: latestPm25,
                    unit: p.unit,
                    subIndex: latestAqi,
                    trend: p.trend,
                    description: p.description,
                  );
                }
                return p;
              }).toList();

              final updatedWeather = WeatherInfo(
                temperatureC: orig.weather.temperatureC,
                humidity: (latestReading.humidity ?? orig.weather.humidity.toDouble()).round(),
                windKph: orig.weather.windKph,
                condition: orig.weather.condition,
                sunrise: orig.weather.sunrise,
                sunset: orig.weather.sunset,
                uvIndex: orig.weather.uvIndex,
              );

              updatedStations[index] = MonitoringStation(
                id: orig.id,
                name: historyResponse.siteName ?? orig.name,
                area: orig.area,
                aqi: latestAqi,
                primaryPollutant: orig.primaryPollutant,
                summary: orig.summary,
                weather: updatedWeather,
                pollutants: updatedPollutants,
                forecast: orig.forecast,
                history: hourlyHistory.isNotEmpty ? hourlyHistory : orig.history,
                advice: orig.advice,
                location: orig.location,
                isOutdoor: orig.isOutdoor,
              );
            }
          }
        } catch (_) {
          // Individual site fetch fallback
        }
      }
    } catch (_) {
      // General API error fallback to static stations
    }

    return updatedStations;
  }
}
