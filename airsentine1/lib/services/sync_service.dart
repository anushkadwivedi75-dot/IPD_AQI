import 'dart:async';
import 'package:airsentine1/data/local_db.dart';
import 'package:airsentine1/services/api_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SyncService {
  final LocalDb _localDb;
  final ApiService _apiService;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  final StreamController<int> _pendingCountController = StreamController<int>.broadcast();

  SyncService({
    LocalDb? localDb,
    ApiService? apiService,
    Connectivity? connectivity,
  })  : _localDb = localDb ?? LocalDb.instance,
        _apiService = apiService ?? ApiService(),
        _connectivity = connectivity ?? Connectivity() {
    _initConnectivityListener();
  }

  Stream<int> get pendingCountStream => _pendingCountController.stream;

  void _initConnectivityListener() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) async {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        await syncPendingData();
      } else {
        await updatePendingCount();
      }
    });
  }

  Future<int> getPendingSyncCount() async {
    return await _localDb.getPendingSyncCount();
  }

  Future<void> updatePendingCount() async {
    final count = await getPendingSyncCount();
    _pendingCountController.add(count);
  }

  /// Sync all un-synced local readings with the backend API
  Future<int> syncPendingData() async {
    try {
      final unsynced = await _localDb.getUnsyncedReadings();
      if (unsynced.isEmpty) {
        await updatePendingCount();
        return 0;
      }

      final response = await _apiService.postReadingsBatch(unsynced);
      if (response.status == 'success' || response.inserted > 0) {
        final idsToMark = unsynced.where((r) => r.id != null).map((r) => r.id!).toList();
        await _localDb.markReadingsSynced(idsToMark);
      }

      // Sync personal Bluetooth telemetry
      final unsyncedTelemetry = await _localDb.getUnsyncedPersonalTelemetry();
      if (unsyncedTelemetry.isNotEmpty) {
        try {
          final payload = unsyncedTelemetry.map((t) => t.toJson()).toList();
          await _apiService.postPersonalTelemetryBatch(payload);
          final telemetryIds = unsyncedTelemetry.where((t) => t.id != null).map((t) => t.id!).toList();
          await _localDb.markPersonalTelemetrySynced(telemetryIds);
        } catch (_) {}
      }

      await updatePendingCount();
      return unsynced.length + unsyncedTelemetry.length;
    } catch (_) {
      await updatePendingCount();
      return 0;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _pendingCountController.close();
  }
}
