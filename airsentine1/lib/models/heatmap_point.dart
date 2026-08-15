class HeatmapPoint {
  final double lat;
  final double lng;
  final double aqi;
  final double weight;

  const HeatmapPoint({
    required this.lat,
    required this.lng,
    required this.aqi,
    required this.weight,
  });

  factory HeatmapPoint.fromJson(Map<String, dynamic> json) {
    return HeatmapPoint(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      aqi: (json['aqi'] as num).toDouble(),
      weight: (json['weight'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'aqi': aqi,
      'weight': weight,
    };
  }
}
