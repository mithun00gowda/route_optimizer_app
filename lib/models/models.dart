import 'package:google_maps_flutter/google_maps_flutter.dart'; // For Google Maps LatLng
import 'dart:developer' as developer; // Import for debugPrint

class RouteCoordinate {
  final double latitude;
  final double longitude;

  RouteCoordinate({required this.latitude, required this.longitude});

  factory RouteCoordinate.fromJson(List<dynamic> json) {
    developer.log('RouteCoordinate.fromJson input: $json'); // Debug print
    if (json.length != 2) {
      throw FormatException('Invalid RouteCoordinate format: expected [lat, lon]');
    }
    return RouteCoordinate(
      latitude: (json[0] as num).toDouble(),
      longitude: (json[1] as num).toDouble(),
    );
  }

  // Helper to convert to Maps_flutter LatLng
  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }
}

class RouteDetails {
  final String routeId;
  final List<RouteCoordinate> geometryCoords;
  final double totalDistanceMeters;
  final int? totalDurationSeconds; // Changed to nullable int
  final double adjustedDurationMinutes;
  final String? predictedSeverity; // Changed to nullable String
  final List<dynamic>? relevantUserReportedAccidents; // Changed to nullable List
  final double score;
  final Map<String, dynamic> detailedImpacts;

  RouteDetails({
    required this.routeId,
    required this.geometryCoords,
    required this.totalDistanceMeters,
    this.totalDurationSeconds,
    this.predictedSeverity, // Updated
    this.relevantUserReportedAccidents, // Updated
    required this.adjustedDurationMinutes,
    required this.score,
    required this.detailedImpacts,
  });

  factory RouteDetails.fromJson(Map<String, dynamic> json) {
    developer.log('RouteDetails.fromJson input: $json'); // Debug print
    return RouteDetails(
      routeId: json['route_id'] as String,
      geometryCoords: (json['geometry_coords'] as List)
          .map((e) => RouteCoordinate.fromJson(e))
          .toList(),
      totalDistanceMeters: (json['total_distance_meters'] as num).toDouble(),
      totalDurationSeconds: (json['total_duration_seconds'] as int?),
      adjustedDurationMinutes:
      (json['adjusted_duration_minutes'] as num).toDouble(),
      predictedSeverity: json['predicted_severity'] as String?, // Allow null
      relevantUserReportedAccidents: json['relevant_user_reported_accidents'] as List<dynamic>?, // Allow null
      score: (json['score'] as num).toDouble(),
      detailedImpacts: json['detailed_impacts'] as Map<String, dynamic>,
    );
  }
}

class WeatherInfo {
  final String? description;
  final double? temperatureCelsius; // Changed to nullable double
  final int? humidityPercent; // Changed to nullable int
  final double? windSpeedMps; // Changed to nullable double
  final int? visibilityMeters; // Changed to nullable int
  final String? category;

  WeatherInfo({
    this.description,
    this.temperatureCelsius, // Updated
    this.humidityPercent, // Updated
    this.windSpeedMps, // Updated
    this.visibilityMeters, // Updated
    this.category,
  });

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    developer.log('WeatherInfo.fromJson input: $json'); // Debug print
    return WeatherInfo(
      description: json['description'] as String?,
      temperatureCelsius: (json['temperature_celsius'] as num?)?.toDouble(), // Allow null, then toDouble
      humidityPercent: (json['humidity_percent'] as int?), // Allow null
      windSpeedMps: (json['wind_speed_mps'] as num?)?.toDouble(), // Allow null, then toDouble
      visibilityMeters: (json['visibility_meters'] as int?), // Allow null
      category: json['category'] as String?,
    );
  }
}

class Accident {
  final String id;
  final double latitude;
  final double longitude;
  final String severity;
  final String type;
  final String? description;
  final double simulatedDelayMinutes;

  Accident({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.severity,
    required this.type,
    this.description,
    required this.simulatedDelayMinutes,
  });

  factory Accident.fromJson(Map<String, dynamic> json) {
    developer.log('Accident.fromJson input: $json'); // Debug print
    return Accident(
      id: (json['id'] is int) ? (json['id'] as int).toString() : json['id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      severity: json['severity'] as String,
      type: json['type'] as String,
      description: json['description'] as String?,
      simulatedDelayMinutes: (json['simulated_delay_minutes'] as num).toDouble(),
    );
  }

  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }
}

class HistoricalAccident {
  final String id;
  final double latitude;
  final double longitude;
  final String severity;
  final String type;
  final String locationName;
  final int year;
  final String involvedVehicleType;
  final int simulatedIncidentCount;
  final String date;
  final String? description;

  HistoricalAccident({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.severity,
    required this.type,
    required this.locationName,
    required this.year,
    required this.involvedVehicleType,
    required this.simulatedIncidentCount,
    required this.date,
    this.description,
  });

  factory HistoricalAccident.fromJson(Map<String, dynamic> json) {
    developer.log('HistoricalAccident.fromJson input: $json'); // Debug print
    return HistoricalAccident(
      id: (json['id'] is int) ? (json['id'] as int).toString() : json['id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      severity: json['severity'] as String,
      type: json['type'] as String,
      locationName: json['location_name'] as String,
      year: json['year'] as int,
      involvedVehicleType: json['involved_vehicle_type'] as String,
      simulatedIncidentCount: (json['simulated_incident_count'] as int),
      date: json['date'] as String,
      description: json['description'] as String?,
    );
  }

  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }
}

class RoutePredictionResult {
  final RouteDetails bestRoute;
  final RouteDetails? notBestRoute;
  final List<RouteDetails> allRoutes;
  final WeatherInfo? weatherInfo;
  final List<Accident> simulatedCurrentAccidents;
  final List<HistoricalAccident> simulatedHistoricalAccidents;
  final RouteCoordinate startCoords;
  final RouteCoordinate endCoords;
  final String vehicleType;
  final List<int> historicalYearRange;

  RoutePredictionResult({
    required this.bestRoute,
    this.notBestRoute,
    required this.allRoutes,
    this.weatherInfo,
    required this.simulatedCurrentAccidents,
    required this.simulatedHistoricalAccidents,
    required this.startCoords,
    required this.endCoords,
    required this.vehicleType,
    required this.historicalYearRange,
  });

  factory RoutePredictionResult.fromJson(Map<String, dynamic> json) {
    developer.log('RoutePredictionResult.fromJson input: $json'); // Debug print
    RouteDetails? parsedNotBestRoute;
    if (json['not_best_route'] != null) {
      parsedNotBestRoute = RouteDetails.fromJson(json['not_best_route']);
    } else if (json['all_routes'] is List && json['all_routes'].length > 1) {
      final List<RouteDetails> all = (json['all_routes'] as List)
          .map((e) => RouteDetails.fromJson(e))
          .toList();
    }


    return RoutePredictionResult(
      bestRoute: RouteDetails.fromJson(json['best_route']),
      notBestRoute: parsedNotBestRoute,
      allRoutes: (json['all_routes'] as List)
          .map((e) => RouteDetails.fromJson(e))
          .toList(),
      weatherInfo: json['weather_info'] != null
          ? WeatherInfo.fromJson(json['weather_info'])
          : null,
      simulatedCurrentAccidents: (json['simulated_current_accidents'] as List)
          .map((e) => Accident.fromJson(e))
          .toList(),
      simulatedHistoricalAccidents:
      (json['simulated_historical_accidents'] as List)
          .map((e) => HistoricalAccident.fromJson(e))
          .toList(),
      startCoords: RouteCoordinate.fromJson(json['start_coords']),
      endCoords: RouteCoordinate.fromJson(json['end_coords']),
      vehicleType: json['vehicle_type'] as String,
      historicalYearRange: (json['historical_year_range'] as List).cast<int>(),
    );
  }
}
