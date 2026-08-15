import 'dart:async';
import 'package:airsentine1/data/local_db.dart';
import 'package:airsentine1/models/alert.dart';
import 'package:airsentine1/services/api_service.dart';

class AlertService {
  final ApiService _apiService;
  final LocalDb _localDb;
  Timer? _pollingTimer;

  final StreamController<List<AppAlert>> _alertsStreamController =
      StreamController<List<AppAlert>>.broadcast();

  AlertService({
    ApiService? apiService,
    LocalDb? localDb,
  })  : _apiService = apiService ?? ApiService(),
        _localDb = localDb ?? LocalDb.instance;

  Stream<List<AppAlert>> get alertsStream => _alertsStreamController.stream;

  /// Start polling alerts every 30 seconds
  void startPolling({String? siteId, Duration interval = const Duration(seconds: 30)}) {
    _pollingTimer?.cancel();
    // Immediate poll
    pollAlerts(siteId: siteId);
    _pollingTimer = Timer.periodic(interval, (_) => pollAlerts(siteId: siteId));
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Poll alerts from API, cache in local_db, and emit stream update
  Future<List<AppAlert>> pollAlerts({String? siteId}) async {
    try {
      final remoteAlerts = await _apiService.fetchAlerts(siteId: siteId);
      for (final alert in remoteAlerts) {
        await _localDb.insertReceivedAlert(alert);
      }

      final cachedAlerts = await _localDb.getReceivedAlertsForSite(siteId);
      _alertsStreamController.add(cachedAlerts);
      return cachedAlerts;
    } catch (_) {
      // Fallback to local DB if offline
      final cachedAlerts = await _localDb.getReceivedAlertsForSite(siteId);
      _alertsStreamController.add(cachedAlerts);
      return cachedAlerts;
    }
  }

  /// Trigger spatial analysis for a site and poll updated alerts
  Future<List<AppAlert>> triggerAndPoll(String siteId) async {
    try {
      final newAlerts = await _apiService.triggerAlertAnalysis(siteId);
      for (final alert in newAlerts) {
        await _localDb.insertReceivedAlert(alert);
      }
    } catch (_) {}

    return await pollAlerts(siteId: siteId);
  }

  void dispose() {
    stopPolling();
    _alertsStreamController.close();
  }
}
