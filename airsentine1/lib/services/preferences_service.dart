import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _selectedStationKey = 'selected_station_id';
  static const _favoritesKey = 'favorite_station_ids';
  static const _alertThresholdKey = 'alert_threshold';
  static const _notificationsEnabledKey = 'notifications_enabled';
  static const _useMetricKey = 'use_metric_units';
  static const _isDarkModeKey = 'is_dark_mode';

  final SharedPreferences _preferences;

  PreferencesService._(this._preferences);

  static Future<PreferencesService> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    return PreferencesService._(preferences);
  }

  String? get selectedStationId => _preferences.getString(_selectedStationKey);
  Set<String> get favoriteStationIds => _preferences.getStringList(_favoritesKey)?.toSet() ?? <String>{};
  int get alertThreshold => _preferences.getInt(_alertThresholdKey) ?? 100;
  bool get notificationsEnabled => _preferences.getBool(_notificationsEnabledKey) ?? true;
  bool get useMetricUnits => _preferences.getBool(_useMetricKey) ?? true;
  bool get isDarkMode => _preferences.getBool(_isDarkModeKey) ?? false;

  Future<void> setSelectedStationId(String id) async {
    await _preferences.setString(_selectedStationKey, id);
  }

  Future<void> setFavoriteStationIds(Set<String> ids) async {
    await _preferences.setStringList(_favoritesKey, ids.toList());
  }

  Future<void> setAlertThreshold(int threshold) async {
    await _preferences.setInt(_alertThresholdKey, threshold);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await _preferences.setBool(_notificationsEnabledKey, value);
  }

  Future<void> setUseMetricUnits(bool value) async {
    await _preferences.setBool(_useMetricKey, value);
  }

  Future<void> setIsDarkMode(bool value) async {
    await _preferences.setBool(_isDarkModeKey, value);
  }

  String? getString(String key) => _preferences.getString(key);
  Future<void> setString(String key, String value) async => await _preferences.setString(key, value);
  Future<void> remove(String key) async => await _preferences.remove(key);
}
