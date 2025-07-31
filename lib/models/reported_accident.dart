// lib/models/reported_accident.dart

class ReportedAccident {
  final String id; // Changed to String as per previous fixes
  final double latitude;
  final double longitude;
  final String incidentType;
  final String? description;
  final List<String> mediaPaths;
  final String status;
  final String reportedAt; // Assuming ISO 8601 string

  ReportedAccident({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.incidentType,
    this.description,
    required this.mediaPaths,
    required this.status,
    required this.reportedAt,
  });

  factory ReportedAccident.fromJson(Map<String, dynamic> json) {
    return ReportedAccident(
      id: (json['id'] is int) ? (json['id'] as int).toString() : json['id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      incidentType: json['incident_type'] as String,
      description: json['description'] as String?,
      mediaPaths: List<String>.from(json['media_paths'] as List),
      status: json['status'] as String,
      reportedAt: json['reported_at'] as String,
    );
  }
}
