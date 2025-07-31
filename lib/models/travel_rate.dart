// lib/models/travel_rate.dart

class TravelRate {
  final String username;
  final int totalTrips;
  final double totalDistanceKm;
  final double totalDurationHours;
  final double avgRouteScore;

  TravelRate({
    required this.username,
    required this.totalTrips,
    required this.totalDistanceKm,
    required this.totalDurationHours,
    required this.avgRouteScore,
  });

  factory TravelRate.fromJson(Map<String, dynamic> json) {
    return TravelRate(
      username: json['username'] as String,
      totalTrips: json['total_trips'] as int,
      totalDistanceKm: (json['total_distance_km'] as num).toDouble(),
      totalDurationHours: (json['total_duration_hours'] as num).toDouble(),
      avgRouteScore: (json['avg_route_score'] as num).toDouble(),
    );
  }
}
