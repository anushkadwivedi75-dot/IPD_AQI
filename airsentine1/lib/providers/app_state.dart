import 'package:airsentine1/data/sample_data.dart';
import 'package:airsentine1/models/station.dart';
import 'package:airsentine1/services/preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  throw UnimplementedError('PreferencesService has not been initialized.');
});

/// List of available CPCB monitoring stations
final stationsListProvider = Provider<List<MonitoringStation>>((ref) {
  return stations;
});

/// Currently selected station ID
final selectedStationIdProvider = StateNotifierProvider<SelectedStationIdNotifier, String>((ref) {
  final service = ref.watch(preferencesServiceProvider);
  final allStations = ref.watch(stationsListProvider);
  return SelectedStationIdNotifier(
    service,
    initialStationId: service.selectedStationId ?? allStations.first.id,
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

/// Favorite station IDs set
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

/// AQI Alert Threshold (default 200 - CPCB Poor threshold)
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

/// Notification preference state
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

/// Unit preference state
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

/// Active selected station model
final selectedStationProvider = Provider<MonitoringStation>((ref) {
  final selectedId = ref.watch(selectedStationIdProvider);
  final allStations = ref.watch(stationsListProvider);
  return allStations.firstWhere(
    (station) => station.id == selectedId,
    orElse: () => allStations.first,
  );
});

/// Favorite stations list model
final favoriteStationsListProvider = Provider<List<MonitoringStation>>((ref) {
  final favorites = ref.watch(favoriteStationIdsProvider);
  final allStations = ref.watch(stationsListProvider);
  return allStations.where((station) => favorites.contains(station.id)).toList();
});

/// AQI Alarm active indicator
final aqiAlarmProvider = Provider<bool>((ref) {
  final threshold = ref.watch(alertThresholdProvider);
  final station = ref.watch(selectedStationProvider);
  return station.aqi >= threshold;
});

/// Modal visibility states
final isStationDetailOpenProvider = StateProvider<bool>((ref) => false);
final isAiAssistantOpenProvider = StateProvider<bool>((ref) => false);

/// Theme Mode state (Light vs Dark)
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final service = ref.watch(preferencesServiceProvider);
  return ThemeModeNotifier(service, initialDarkMode: service.isDarkMode);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._service, {required bool initialDarkMode})
      : super(initialDarkMode ? ThemeMode.dark : ThemeMode.light);

  final PreferencesService _service;

  Future<void> toggleTheme() async {
    final isDark = state == ThemeMode.dark;
    state = isDark ? ThemeMode.light : ThemeMode.dark;
    await _service.setIsDarkMode(!isDark);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _service.setIsDarkMode(mode == ThemeMode.dark);
  }
}

