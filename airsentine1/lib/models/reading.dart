class Reading {
  final int? id;
  final String? deviceId;
  final int? aqi;
  final double? pm25;
  final double? humidity;
  final double lat;
  final double lng;
  final DateTime? recordedAt;

  const Reading({
    this.id,
    this.deviceId,
    this.aqi,
    this.pm25,
    this.humidity,
    required this.lat,
    required this.lng,
    this.recordedAt,
  });

  factory Reading.fromJson(Map<String, dynamic> json) {
    return Reading(
      id: json['id'] as int?,
      deviceId: json['device_id'] as String?,
      aqi: json['aqi'] as int?,
      pm25: (json['pm25'] as num?)?.toDouble(),
      humidity: (json['humidity'] as num?)?.toDouble(),
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      recordedAt: json['recorded_at'] != null ? DateTime.parse(json['recorded_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (deviceId != null) 'device_id': deviceId,
      if (aqi != null) 'aqi': aqi,
      if (pm25 != null) 'pm25': pm25,
      if (humidity != null) 'humidity': humidity,
      'lat': lat,
      'lng': lng,
      if (recordedAt != null) 'recorded_at': recordedAt!.toIso8601String(),
    };
  }
}

class BatchReadingResponse {
  final int inserted;
  final String status;

  const BatchReadingResponse({
    required this.inserted,
    required this.status,
  });

  factory BatchReadingResponse.fromJson(Map<String, dynamic> json) {
    return BatchReadingResponse(
      inserted: json['inserted'] as int,
      status: json['status'] as String? ?? 'success',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inserted': inserted,
      'status': status,
    };
  }
}
