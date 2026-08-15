import 'package:airsentine1/models/reading.dart';

class SiteHistoryResponse {
  final String siteId;
  final String? siteName;
  final int hours;
  final List<Reading> readings;

  const SiteHistoryResponse({
    required this.siteId,
    this.siteName,
    required this.hours,
    required this.readings,
  });

  factory SiteHistoryResponse.fromJson(Map<String, dynamic> json) {
    return SiteHistoryResponse(
      siteId: json['site_id'] as String,
      siteName: json['site_name'] as String?,
      hours: json['hours'] as int? ?? 24,
      readings: (json['readings'] as List<dynamic>?)
              ?.map((item) => Reading.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'site_id': siteId,
      if (siteName != null) 'site_name': siteName,
      'hours': hours,
      'readings': readings.map((r) => r.toJson()).toList(),
    };
  }
}
