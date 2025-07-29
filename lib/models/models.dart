// lib/models.dart
import 'package:google_maps_flutter/google_maps_flutter.dart'; // For Google Maps LatLng

class RouteCoordinate {
  final double latitude;
  final double longitude;

  RouteCoordinate({required this.latitude, required this.longitude});

  factory RouteCoordinate.fromJson(List<dynamic> json) {
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
  final double totalDurationMinutes;
  final double adjustedDurationMinutes;
  final double score; // Add score here
  final Map<String, dynamic> detailedImpacts; // Add detailed impacts

  RouteDetails({
    required this.routeId,
    required this.geometryCoords,
    required this.totalDistanceMeters,
    required this.totalDurationMinutes,
    required this.adjustedDurationMinutes,
    required this.score,
    required this.detailedImpacts,
  });

  factory RouteDetails.fromJson(Map<String, dynamic> json) {
    return RouteDetails(
      routeId: json['route_id'] as String,
      geometryCoords: (json['geometry_coords'] as List)
          .map((e) => RouteCoordinate.fromJson(e))
          .toList(),
      totalDistanceMeters: (json['total_distance_meters'] as num).toDouble(),
      totalDurationMinutes: (json['total_duration_minutes'] as num).toDouble(),
      adjustedDurationMinutes:
      (json['adjusted_duration_minutes'] as num).toDouble(),
      score: (json['score'] as num).toDouble(), // Parse score
      detailedImpacts: json['detailed_impacts'] as Map<String, dynamic>, // Parse detailed impacts
    );
  }
}

class WeatherInfo {
  final String description;
  final double temperatureCelsius;
  final dynamic windspeedKmh; // Using dynamic as it could be num or string
  final dynamic weathercode; // Using dynamic as it could be num or string

  WeatherInfo({
    required this.description,
    required this.temperatureCelsius,
    required this.windspeedKmh,
    required this.weathercode,
  });

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    return WeatherInfo(
      description: json['description'] as String,
      temperatureCelsius: (json['temperature_celsius'] as num).toDouble(),
      windspeedKmh: json['windspeed_kmh'],
      weathercode: json['weathercode'],
    );
  }
}

class Accident {
  final String id; // Added unique ID
  final double latitude;
  final double longitude;
  final String severity;
  final String type; // Renamed from 'description' to 'type' to match backend's 'type' field
  final double simulatedDelayMinutes; // Ensure this matches backend

  Accident({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.severity,
    required this.type,
    required this.simulatedDelayMinutes,
  });

  factory Accident.fromJson(Map<String, dynamic> json) {
    return Accident(
      id: json['id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      severity: json['severity'] as String,
      type: json['type'] as String, // Using 'type'
      simulatedDelayMinutes: (json['simulated_delay_minutes'] as num).toDouble(),
    );
  }

  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }
}

class HistoricalAccident {
  final String id; // Added unique ID
  final double latitude;
  final double longitude;
  final String severity;
  final String type; // Using 'type' to match backend
  final String locationName; // From backend's 'location_name'
  final int year;
  final String involvedVehicleType;
  final int simulatedIncidentCount;
  final String date; // Example date field from backend

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
  });

  factory HistoricalAccident.fromJson(Map<String, dynamic> json) {
    return HistoricalAccident(
      id: json['id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      severity: json['severity'] as String,
      type: json['type'] as String, // Using 'type'
      locationName: json['location_name'] as String,
      year: json['year'] as int,
      involvedVehicleType: json['involved_vehicle_type'] as String,
      simulatedIncidentCount: json['simulated_incident_count'] as int,
      date: json['date'] as String,
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
  final String vehicleType; // Added
  final List<int> historicalYearRange; // Added

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
    return RoutePredictionResult(
      bestRoute: RouteDetails.fromJson(json['best_route']),
      notBestRoute: json['not_best_route'] != null
          ? RouteDetails.fromJson(json['not_best_route'])
          : null,
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