// lib/models/daily_trip.dart

class DailyTrip {
  final String date;
  final int tripCount;
  final double totalDistanceKm;

  DailyTrip({
    required this.date,
    required this.tripCount,
    required this.totalDistanceKm,
  });

  factory DailyTrip.fromJson(Map<String, dynamic> json) {
    return DailyTrip(
      date: json['date'] as String,
      tripCount: json['trip_count'] as int,
      totalDistanceKm: (json['total_distance_km'] as num).toDouble(),
    );
  }
}
