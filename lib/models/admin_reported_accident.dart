// lib/models/admin_reported_accident.dart

class AdminReportedAccident {
  final int id;
  final String reportedByUsername;
  final double latitude;
  final double longitude;
  final String incidentType;
  final String? description;
  final List<String> mediaPaths;
  final String status;
  final String reportedAt;
  final String lastUpdated;

  AdminReportedAccident({
    required this.id,
    required this.reportedByUsername,
    required this.latitude,
    required this.longitude,
    required this.incidentType,
    this.description,
    required this.mediaPaths,
    required this.status,
    required this.reportedAt,
    required this.lastUpdated,
  });

  factory AdminReportedAccident.fromJson(Map<String, dynamic> json) {
    return AdminReportedAccident(
      id: json['id'] as int,
      reportedByUsername: json['reported_by_username'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      incidentType: json['incident_type'] as String,
      description: json['description'] as String?,
      mediaPaths: List<String>.from(json['media_paths'] as List),
      status: json['status'] as String,
      reportedAt: json['reported_at'] as String,
      lastUpdated: json['last_updated'] as String,
    );
  }
}
