// lib/models/models.dart

// Export all your models from here
import 'package:google_maps_flutter/google_maps_flutter.dart';

export 'package:google_maps_flutter/google_maps_flutter.dart';

export 'reported_accident.dart'; // Existing export
export 'admin_dashboard_overview.dart'; // New export
export 'user.dart';                  // New export
export 'admin_reported_accident.dart'; // New export
export 'travel_rate.dart';           // New export
export 'daily_trip.dart';            // New export

// Helper class for coordinates
class LatLon {
  final double latitude;
  final double longitude;

  LatLon(this.latitude, this.longitude);

  factory LatLon.fromJson(List<dynamic> json) {
    return LatLon((json[0] as num).toDouble(), (json[1] as num).toDouble());
  }

  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }
}

// Route Prediction Result Model
class RoutePredictionResult {
  final BestRoute bestRoute;
  final NotBestRoute? notBestRoute;
  final List<RouteDetails> allRoutes;
  final WeatherInfo? weatherInfo;
  final List<AccidentInfo> simulatedCurrentAccidents;
  final List<HistoricalAccidentInfo> simulatedHistoricalAccidents;
  final List<int> historicalYearRange;
  final String vehicleType;

  RoutePredictionResult({
    required this.bestRoute,
    this.notBestRoute,
    required this.allRoutes,
    this.weatherInfo,
    required this.simulatedCurrentAccidents,
    required this.simulatedHistoricalAccidents,
    required this.historicalYearRange,
    required this.vehicleType,
  });

  factory RoutePredictionResult.fromJson(Map<String, dynamic> json) {
    return RoutePredictionResult(
      bestRoute: BestRoute.fromJson(json['best_route']),
      notBestRoute: json['not_best_route'] != null
          ? NotBestRoute.fromJson(json['not_best_route'])
          : null,
      allRoutes: (json['all_routes'] as List)
          .map((i) => RouteDetails.fromJson(i))
          .toList(),
      weatherInfo: json['weather_info'] != null
          ? WeatherInfo.fromJson(json['weather_info'])
          : null,
      simulatedCurrentAccidents: (json['simulated_current_accidents'] as List)
          .map((i) => AccidentInfo.fromJson(i))
          .toList(),
      simulatedHistoricalAccidents:
      (json['simulated_historical_accidents'] as List)
          .map((i) => HistoricalAccidentInfo.fromJson(i))
          .toList(),
      historicalYearRange:
      List<int>.from(json['historical_year_range'] as List),
      vehicleType: json['vehicle_type'] as String,
    );
  }
}

// Route Details Model
class RouteDetails {
  final double adjustedDurationMinutes;
  final List<double> bbox;
  final Map<String, dynamic> detailedImpacts;
  final double duration;
  final List<LatLon> geometryCoords;
  final String routeId;
  final double score;
  final double totalDistanceMeters;
  final String? predictedSeverity;

  RouteDetails({
    required this.adjustedDurationMinutes,
    required this.bbox,
    required this.detailedImpacts,
    required this.duration,
    required this.geometryCoords,
    required this.routeId,
    required this.score,
    required this.totalDistanceMeters,
    this.predictedSeverity,
  });

  factory RouteDetails.fromJson(Map<String, dynamic> json) {
    return RouteDetails(
      adjustedDurationMinutes: (json['adjusted_duration_minutes'] as num).toDouble(),
      bbox: List<double>.from(json['bbox'] as List),
      detailedImpacts: Map<String, dynamic>.from(json['detailed_impacts']),
      duration: (json['duration'] as num).toDouble(),
      geometryCoords: (json['geometry_coords'] as List)
          .map((i) => LatLon.fromJson(i))
          .toList(),
      routeId: json['route_id'] as String,
      score: (json['score'] as num).toDouble(),
      totalDistanceMeters: (json['total_distance_meters'] as num).toDouble(),
      predictedSeverity: json['predicted_severity'] as String?,
    );
  }
}

// Best Route Model
class BestRoute extends RouteDetails {
  BestRoute({
    required double adjustedDurationMinutes,
    required List<double> bbox,
    required Map<String, dynamic> detailedImpacts,
    required double duration,
    required List<LatLon> geometryCoords,
    required String routeId,
    required double score,
    required double totalDistanceMeters,
    String? predictedSeverity,
  }) : super(
    adjustedDurationMinutes: adjustedDurationMinutes,
    bbox: bbox,
    detailedImpacts: detailedImpacts,
    duration: duration,
    geometryCoords: geometryCoords,
    routeId: routeId,
    score: score,
    totalDistanceMeters: totalDistanceMeters,
    predictedSeverity: predictedSeverity,
  );

  factory BestRoute.fromJson(Map<String, dynamic> json) {
    return BestRoute(
      adjustedDurationMinutes: (json['adjusted_duration_minutes'] as num).toDouble(),
      bbox: List<double>.from(json['bbox'] as List),
      detailedImpacts: Map<String, dynamic>.from(json['detailed_impacts']),
      duration: (json['duration'] as num).toDouble(),
      geometryCoords: (json['geometry_coords'] as List)
          .map((i) => LatLon.fromJson(i))
          .toList(),
      routeId: json['route_id'] as String,
      score: (json['score'] as num).toDouble(),
      totalDistanceMeters: (json['total_distance_meters'] as num).toDouble(),
      predictedSeverity: json['predicted_severity'] as String?,
    );
  }
}

// Not Best Route Model
class NotBestRoute extends RouteDetails {
  NotBestRoute({
    required double adjustedDurationMinutes,
    required List<double> bbox,
    required Map<String, dynamic> detailedImpacts,
    required double duration,
    required List<LatLon> geometryCoords,
    required String routeId,
    required double score,
    required double totalDistanceMeters,
    String? predictedSeverity,
  }) : super(
    adjustedDurationMinutes: adjustedDurationMinutes,
    bbox: bbox,
    detailedImpacts: detailedImpacts,
    duration: duration,
    geometryCoords: geometryCoords,
    routeId: routeId,
    score: score,
    totalDistanceMeters: totalDistanceMeters,
    predictedSeverity: predictedSeverity,
  );

  factory NotBestRoute.fromJson(Map<String, dynamic> json) {
    return NotBestRoute(
      adjustedDurationMinutes: (json['adjusted_duration_minutes'] as num).toDouble(),
      bbox: List<double>.from(json['bbox'] as List),
      detailedImpacts: Map<String, dynamic>.from(json['detailed_impacts']),
      duration: (json['duration'] as num).toDouble(),
      geometryCoords: (json['geometry_coords'] as List)
          .map((i) => LatLon.fromJson(i))
          .toList(),
      routeId: json['route_id'] as String,
      score: (json['score'] as num).toDouble(),
      totalDistanceMeters: (json['total_distance_meters'] as num).toDouble(),
      predictedSeverity: json['predicted_severity'] as String?,
    );
  }
}

// Weather Info Model
class WeatherInfo {
  final String? description;
  final double? temperatureCelsius;
  final int? humidityPercent;
  final double? windSpeedMps;
  final int? visibilityMeters;
  final String? category;

  WeatherInfo({
    this.description,
    this.temperatureCelsius,
    this.humidityPercent,
    this.windSpeedMps,
    this.visibilityMeters,
    this.category,
  });

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    return WeatherInfo(
      description: json['description'] as String?,
      temperatureCelsius: (json['temperature_celsius'] as num?)?.toDouble(),
      humidityPercent: json['humidity_percent'] as int?,
      windSpeedMps: (json['wind_speed_mps'] as num?)?.toDouble(),
      visibilityMeters: json['visibility_meters'] as int?,
      category: json['category'] as String?,
    );
  }
}

// Accident Info Model (for current incidents)
class AccidentInfo {
  final String id;
  final double? latitude;
  final double? longitude;
  final String? type;
  final String? severity;
  final String? description;
  final double? simulatedDelayMinutes;

  AccidentInfo({
    required this.id,
    this.latitude,
    this.longitude,
    this.type,
    this.severity,
    this.description,
    this.simulatedDelayMinutes,
  });

  factory AccidentInfo.fromJson(Map<String, dynamic> json) {
    return AccidentInfo(
      id: (json['id'] is int) ? (json['id'] as int).toString() : json['id'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      type: json['type'] as String?,
      severity: json['severity'] as String?,
      description: json['description'] as String?,
      simulatedDelayMinutes: (json['simulated_delay_minutes'] as num?)?.toDouble(),
    );
  }

  LatLng toLatLng() {
    return LatLng(latitude ?? 0.0, longitude ?? 0.0);
  }
}

// Historical Accident Info Model
class HistoricalAccidentInfo {
  final String id;
  final String? locationName;
  final String? type;
  final String? severity;
  final int? year;
  final String? involvedVehicleType;
  final int? simulatedIncidentCount;
  final String? date;
  final double? latitude;
  final double? longitude;
  final String? description;

  HistoricalAccidentInfo({
    required this.id,
    this.locationName,
    this.type,
    this.severity,
    this.year,
    this.involvedVehicleType,
    this.simulatedIncidentCount,
    this.date,
    this.latitude,
    this.longitude,
    this.description,
  });

  factory HistoricalAccidentInfo.fromJson(Map<String, dynamic> json) {
    return HistoricalAccidentInfo(
      id: (json['id'] is int) ? (json['id'] as int).toString() : json['id'] as String,
      locationName: json['location_name'] as String?,
      type: json['type'] as String?,
      severity: json['severity'] as String?,
      year: json['year'] as int?,
      involvedVehicleType: json['involved_vehicle_type'] as String?,
      simulatedIncidentCount: json['simulated_incident_count'] as int?,
      date: json['date'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      description: json['description'] as String?,
    );
  }

  LatLng toLatLng() {
    return LatLng(latitude ?? 0.0, longitude ?? 0.0);
  }
}
