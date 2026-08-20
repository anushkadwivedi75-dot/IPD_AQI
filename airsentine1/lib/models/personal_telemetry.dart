class PersonalTelemetry {
  final int? id;
  final String userId;
  final String deviceId;
  final String? deviceName;
  final int aqi;
  final double pm25;
  final double pm10;
  final double temperature;
  final double humidity;
  final int? heartRate;
  final double lat;
  final double lng;
  final DateTime timestamp;
  final bool isSynced;

  const PersonalTelemetry({
    this.id,
    required this.userId,
    required this.deviceId,
    this.deviceName,
    required this.aqi,
    required this.pm25,
    required this.pm10,
    required this.temperature,
    required this.humidity,
    this.heartRate,
    required this.lat,
    required this.lng,
    required this.timestamp,
    this.isSynced = false,
  });

  factory PersonalTelemetry.fromJson(Map<String, dynamic> json) {
    return PersonalTelemetry(
      id: json['id'] as int?,
      userId: json['user_id'] as String? ?? 'guest',
      deviceId: json['device_id'] as String? ?? 'ble-sensor-01',
      deviceName: json['device_name'] as String? ?? 'AirSentinel BLE Pod',
      aqi: (json['aqi'] as num?)?.toInt() ?? 0,
      pm25: (json['pm25'] as num?)?.toDouble() ?? 0.0,
      pm10: (json['pm10'] as num?)?.toDouble() ?? 0.0,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 25.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 50.0,
      heartRate: (json['heart_rate'] as num?)?.toInt(),
      lat: (json['lat'] as num?)?.toDouble() ?? 28.6139,
      lng: (json['lng'] as num?)?.toDouble() ?? 77.2090,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : (json['recorded_at'] != null
              ? DateTime.parse(json['recorded_at'] as String)
              : DateTime.now()),
      isSynced: (json['is_synced'] as int?) == 1 || (json['is_synced'] as bool?) == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'device_id': deviceId,
      'device_name': deviceName,
      'aqi': aqi,
      'pm25': pm25,
      'pm10': pm10,
      'temperature': temperature,
      'humidity': humidity,
      'heart_rate': heartRate,
      'lat': lat,
      'lng': lng,
      'timestamp': timestamp.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  String get aqiCategory {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive Groups';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }
}
