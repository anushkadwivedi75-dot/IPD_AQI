import 'package:airsentine1/models/alert.dart';
import 'package:airsentine1/models/heatmap_point.dart';
import 'package:airsentine1/models/reading.dart';
import 'package:airsentine1/models/site_history_response.dart';
import 'package:dio/dio.dart';

const String kDefaultBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

class ApiService {
  final Dio _dio;
  final String baseUrl;

  ApiService({
    String? baseUrl,
    Dio? dio,
  })  : baseUrl = baseUrl ?? kDefaultBaseUrl,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? kDefaultBaseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: {'Content-Type': 'application/json'},
              ),
            );

  /// 1. GET /api/heatmap?min_lat&min_lng&max_lat&max_lng
  Future<List<HeatmapPoint>> fetchHeatmap({
    required double minLat,
    required double minLng,
    required double maxLat,
    required double maxLng,
  }) async {
    try {
      final response = await _dio.get(
        '/api/heatmap',
        queryParameters: {
          'min_lat': minLat,
          'min_lng': minLng,
          'max_lat': maxLat,
          'max_lng': maxLng,
        },
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => HeatmapPoint.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// 2. GET /api/sites/{id}/history?hours=24
  Future<SiteHistoryResponse> fetchSiteHistory(
    String siteId, {
    int hours = 24,
  }) async {
    try {
      final response = await _dio.get(
        '/api/sites/$siteId/history',
        queryParameters: {
          'hours': hours,
        },
      );

      return SiteHistoryResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// 3. POST /api/readings/batch
  Future<BatchReadingResponse> postReadingsBatch(List<Reading> readings) async {
    try {
      final payload = readings.map((r) => r.toJson()).toList();
      final response = await _dio.post(
        '/api/readings/batch',
        data: payload,
      );

      return BatchReadingResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// 4. GET /api/alerts?site_id=
  Future<List<AppAlert>> fetchAlerts({String? siteId}) async {
    try {
      final response = await _dio.get(
        '/api/alerts',
        queryParameters: siteId != null ? {'site_id': siteId} : null,

      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => AppAlert.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// 5. POST /api/alerts (trigger analysis)
  Future<List<AppAlert>> triggerAlertAnalysis(String siteId) async {
    try {
      final response = await _dio.post(
        '/api/alerts',
        data: {'site_id': siteId},
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => AppAlert.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// 6. POST /api/auth/login
  Future<Map<String, dynamic>> loginUser({required String email, required String password}) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// 7. POST /api/auth/register
  Future<Map<String, dynamic>> registerUser({required String name, required String email, required String password}) async {
    try {
      final response = await _dio.post(
        '/api/auth/register',
        data: {'name': name, 'email': email, 'password': password},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// 8. POST /api/telemetry/upload
  Future<Map<String, dynamic>> postPersonalTelemetryBatch(List<Map<String, dynamic>> telemetryData) async {
    try {
      final response = await _dio.post(
        '/api/telemetry/upload',
        data: telemetryData,
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}


