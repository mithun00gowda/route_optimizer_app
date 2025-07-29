// lib/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  // IMPORTANT: Replace with your actual backend IP address if not running on emulator/local device
  // For Android Emulator, '10.0.2.2' refers to your host machine's localhost.
  // For iOS Simulator/Physical Device, 'localhost' or your machine's actual IP address.
  // For a physical Android device, you MUST use your computer's local IP address (e.g., '192.168.1.100')
  // static const String _baseUrl = 'http://127.0.0.1:5001'; // For Android Emulator
  // static const String _baseUrl = 'http://localhost:5001'; // For iOS Simulator/Device
  static const String _baseUrl = 'http://172.20.10.2:5001'; // For Physical Android Device (replace X.X with your actual IP)


  static Future<RoutePredictionResult> getRoutePrediction({ // Renamed to match main.dart's use
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    required String vehicleType,
    required int histStartYear,
    required int histEndYear,
  }) async {
    final url = Uri.parse('$_baseUrl/calculate_route'); // Matches Flask endpoint
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'start_lat': startLat,
      'start_lon': startLon,
      'end_lat': endLat,
      'end_lon': endLon,
      'vehicle_type': vehicleType,
      'hist_start_year': histStartYear,
      'hist_end_year': histEndYear,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return RoutePredictionResult.fromJson(jsonResponse);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception('Failed to load route prediction: ${response.statusCode} - ${errorBody.get('error', 'Unknown error')}');
      }
    } catch (e) {
      throw Exception('Error connecting to backend: $e');
    }
  }
}