import 'package:airsentine1/data/local_db.dart';
import 'package:airsentine1/data/sample_data.dart';
import 'package:airsentine1/models/heatmap_point.dart';
import 'package:airsentine1/models/reading.dart';
import 'package:airsentine1/models/site_history_response.dart';
import 'package:airsentine1/models/station.dart';
import 'package:airsentine1/services/api_service.dart';
import 'package:airsentine1/services/sync_service.dart';
import 'package:intl/intl.dart';

class AqiRepository {
  final ApiService _apiService;
  final LocalDb _localDb;
  final SyncService _syncService;

  AqiRepository({
    ApiService? apiService,
    LocalDb? localDb,
    SyncService? syncService,
  })  : _apiService = apiService ?? ApiService(),
        _localDb = localDb ?? LocalDb.instance,
        _syncService = syncService ?? SyncService();

  /// Writes always go to local_db first with is_synced=0,
  /// followed by an immediate sync attempt if online.
  Future<void> saveReading(Reading reading) async {
    await _localDb.insertLocalReading(reading, isSynced: false);
    await _syncService.updatePendingCount();
    // Attempt immediate sync
    await _syncService.syncPendingData();
  }

  /// Bulk post readings: saves to local_db first then syncs
  Future<BatchReadingResponse> postReadingsBatch(List<Reading> readings) async {
    for (final r in readings) {
      await _localDb.insertLocalReading(r, isSynced: false);
    }
    await _syncService.updatePendingCount();
    final syncedCount = await _syncService.syncPendingData();
    return BatchReadingResponse(
      inserted: readings.length,
      status: syncedCount == readings.length ? 'success' : 'pending_offline',
    );
  }

  /// Fetch heatmap points: loads from cached SQLite first,
  /// then triggers background API refresh if online.
  Future<List<HeatmapPoint>> fetchHeatmap({
    double minLat = 18.8,
    double minLng = 72.7,
    double maxLat = 19.2,
    double maxLng = 73.0,
  }) async {
    // 1. Try local cache first
    final localPoints = await _localDb.getCachedHeatmap();

    // 2. Trigger background refresh from network
    _refreshHeatmapBackground(
      minLat: minLat,
      minLng: minLng,
      maxLat: maxLat,
      maxLng: maxLng,
    );

    if (localPoints.isNotEmpty) {
      return localPoints;
    }

    // 3. Fallback to API directly if local cache empty
    try {
      final remotePoints = await _apiService.fetchHeatmap(
        minLat: minLat,
        minLng: minLng,
        maxLat: maxLat,
        maxLng: maxLng,
      );
      await _localDb.saveCachedHeatmap(remotePoints);
      return remotePoints;
    } catch (_) {
      return [];
    }
  }

  Future<void> _refreshHeatmapBackground({
    required double minLat,
    required double minLng,
    required double maxLat,
    required double maxLng,
  }) async {
    try {
      final remotePoints = await _apiService.fetchHeatmap(
        minLat: minLat,
        minLng: minLng,
        maxLat: maxLat,
        maxLng: maxLng,
      );
      await _localDb.saveCachedHeatmap(remotePoints);
    } catch (_) {
      // Ignore background network errors
    }
  }

  /// Fetch site history readings
  Future<SiteHistoryResponse> fetchSiteHistory(
    String siteId, {
    int hours = 24,
  }) async {
    return await _apiService.fetchSiteHistory(siteId, hours: hours);
  }

  /// Get monitoring stations: loads local cached stations first,
  /// then refreshes from backend API in background.
  Future<List<MonitoringStation>> getStations() async {
    final List<MonitoringStation> updatedStations = List.from(stations);

    try {
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
          // Individual site fallback
        }
      }

      await _localDb.saveCachedSites(updatedStations);
    } catch (_) {
      // General API error: try retrieving cached sites from localDb
      final cached = await _localDb.getCachedSites();
      if (cached.isNotEmpty) {
        return cached;
      }
    }

    return updatedStations;
  }
}
