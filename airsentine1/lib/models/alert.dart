class AppAlert {
  final String id;
  final String? siteId;
  final String? type;
  final int? severity;
  final Map<String, dynamic>? evidence;
  final DateTime? receivedAt;

  const AppAlert({
    required this.id,
    this.siteId,
    this.type,
    this.severity,
    this.evidence,
    this.receivedAt,
  });

  factory AppAlert.fromJson(Map<String, dynamic> json) {
    return AppAlert(
      id: json['id'] as String,
      siteId: json['site_id'] as String?,
      type: json['type'] as String?,
      severity: json['severity'] as int?,
      evidence: json['evidence'] is Map<String, dynamic>
          ? json['evidence'] as Map<String, dynamic>
          : null,
      receivedAt: json['received_at'] != null
          ? DateTime.parse(json['received_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (siteId != null) 'site_id': siteId,
      if (type != null) 'type': type,
      if (severity != null) 'severity': severity,
      if (evidence != null) 'evidence': evidence,
      if (receivedAt != null) 'received_at': receivedAt!.toIso8601String(),
    };
  }
}
