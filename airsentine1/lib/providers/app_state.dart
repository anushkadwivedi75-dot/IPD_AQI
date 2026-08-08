import 'package:airsentine1/data/sample_data.dart';
import 'package:airsentine1/models/station.dart';
import 'package:airsentine1/services/preferences_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  throw UnimplementedError('PreferencesService has not been initialized.');
});

final selectedStationIdProvider = StateNotifierProvider<SelectedStationIdNotifier, String>((ref) {
  final service = ref.watch(preferencesServiceProvider);
  return SelectedStationIdNotifier(
    service,
    initialStationId: service.selectedStationId ?? stations.first.id,
  );
});

class SelectedStationIdNotifier extends StateNotifier<String> {
  SelectedStationIdNotifier(this._service, {required String initialStationId}) : super(initialStationId);

  final PreferencesService _service;

  Future<void> setStation(String stationId) async {
    state = stationId;
    await _service.setSelectedStationId(stationId);
  }
}

final favoriteStationIdsProvider = StateNotifierProvider<FavoriteStationsNotifier, Set<String>>((ref) {
  final service = ref.watch(preferencesServiceProvider);
  return FavoriteStationsNotifier(service, initialFavorites: service.favoriteStationIds);
});

class FavoriteStationsNotifier extends StateNotifier<Set<String>> {
  FavoriteStationsNotifier(this._service, {required Set<String> initialFavorites}) : super(initialFavorites);

  final PreferencesService _service;

  Future<void> toggleFavorite(String stationId) async {
    final updated = Set<String>.from(state);
    if (updated.contains(stationId)) {
      updated.remove(stationId);
    } else {
      updated.add(stationId);
    }
    state = updated;
    await _service.setFavoriteStationIds(updated);
  }
}

final alertThresholdProvider = StateNotifierProvider<AlertThresholdNotifier, int>((ref) {
  final service = ref.watch(preferencesServiceProvider);
  return AlertThresholdNotifier(service, initialThreshold: service.alertThreshold);
});

class AlertThresholdNotifier extends StateNotifier<int> {
  AlertThresholdNotifier(this._service, {required int initialThreshold}) : super(initialThreshold);

  final PreferencesService _service;

  Future<void> setThreshold(int threshold) async {
    state = threshold;
    await _service.setAlertThreshold(threshold);
  }
}

final notificationEnabledProvider = StateNotifierProvider<NotificationEnabledNotifier, bool>((ref) {
  final service = ref.watch(preferencesServiceProvider);
  return NotificationEnabledNotifier(service, initialEnabled: service.notificationsEnabled);
});

class NotificationEnabledNotifier extends StateNotifier<bool> {
  NotificationEnabledNotifier(this._service, {required bool initialEnabled}) : super(initialEnabled);

  final PreferencesService _service;

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await _service.setNotificationsEnabled(enabled);
  }
}

final unitPreferenceProvider = StateNotifierProvider<UnitPreferenceNotifier, bool>((ref) {
  final service = ref.watch(preferencesServiceProvider);
  return UnitPreferenceNotifier(service, initialUseMetric: service.useMetricUnits);
});

class UnitPreferenceNotifier extends StateNotifier<bool> {
  UnitPreferenceNotifier(this._service, {required bool initialUseMetric}) : super(initialUseMetric);

  final PreferencesService _service;

  Future<void> toggleUnits() async {
    state = !state;
    await _service.setUseMetricUnits(state);
  }
}

final selectedStationProvider = Provider<Station>((ref) {
  final selectedId = ref.watch(selectedStationIdProvider);
  return stations.firstWhere((station) => station.id == selectedId, orElse: () => stations.first);
});

final favoriteStationsListProvider = Provider<List<Station>>((ref) {
  final favorites = ref.watch(favoriteStationIdsProvider);
  return stations.where((station) => favorites.contains(station.id)).toList();
});

final aqiAlarmProvider = Provider<bool>((ref) {
  final threshold = ref.watch(alertThresholdProvider);
  final station = ref.watch(selectedStationProvider);
  return station.aqi >= threshold;
});
