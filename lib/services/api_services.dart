import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:optiroute/constants/strings.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart'; // Needed for BuildContext
import '../models/models.dart';
import 'auth_service.dart'; // Import AuthService

class ApiService {
  // TODO: Ensure this matches your Flask backend URL
  static final String _baseUrl = StringsData.BASE_URL;

  // Private helper to make authenticated requests
  static Future<http.Response> _sendAuthenticatedRequest(
      BuildContext context,
      String method,
      String endpoint, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
      }) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    String? accessToken = authService.currentUser?.accessToken;

    if (accessToken == null) {
      // If no token, attempt auto-login or redirect to login
      // For now, we'll just throw an error. In a real app, you might
      // navigate to login screen here.
      throw Exception('Authentication required. Please log in.');
    }

    // Add Authorization header
    final Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
      ...?headers, // Merge any additional headers
    };

    Uri uri = Uri.parse('$_baseUrl$endpoint');
    http.Response response;

    try {
      if (method == 'POST') {
        response = await http.post(
          uri,
          headers: requestHeaders,
          body: json.encode(body),
        );
      } else if (method == 'GET') {
        response = await http.get(
          uri,
          headers: requestHeaders,
        );
      } else if (method == 'PUT') {
        response = await http.put(
          uri,
          headers: requestHeaders,
          body: json.encode(body),
        );
      } else if (method == 'DELETE') {
        response = await http.delete(
          uri,
          headers: requestHeaders,
        );
      } else {
        throw Exception('Unsupported HTTP method: $method');
      }

      // Handle token expiration / refresh
      if (response.statusCode == 401) {
        print('Received 401. Attempting to refresh token...');
        final newAccessToken = await authService.refreshAccessToken();
        if (newAccessToken != null) {
          // Retry the original request with the new token
          print('Token refreshed, retrying request...');
          requestHeaders['Authorization'] = 'Bearer $newAccessToken';
          if (method == 'POST') {
            response = await http.post(uri, headers: requestHeaders, body: json.encode(body));
          } else if (method == 'GET') {
            response = await http.get(uri, headers: requestHeaders);
          } else if (method == 'PUT') {
            response = await http.put(uri, headers: requestHeaders, body: json.encode(body));
          } else if (method == 'DELETE') {
            response = await http.delete(uri, headers: requestHeaders);
          }
        } else {
          // If refresh failed, force logout
          print('Token refresh failed. Logging out user.');
          await authService.logout();
          // You might want to navigate to login screen here
          throw Exception('Session expired. Please log in again.');
        }
      }

      return response;
    } catch (e) {
      print('Network request error: $e');
      rethrow; // Re-throw to be caught by the calling function
    }
  }


  // --- API Endpoints ---

  static Future<RoutePredictionResult> getRoutePrediction({
    required BuildContext context, // Pass BuildContext to access Provider
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    required String vehicleType,
    required int histStartYear,
    required int histEndYear,
  }) async {
    final body = {
      'start_lat': startLat,
      'start_lon': startLon,
      'end_lat': endLat,
      'end_lon': endLon,
      'vehicle_type': vehicleType,
      'hist_start_year': histStartYear,
      'hist_end_year': histEndYear,
    };

    final response = await _sendAuthenticatedRequest(
      context,
      'POST',
      '/api/calculate_route',
      body: body,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return RoutePredictionResult.fromJson(data);

    } else {
      final Map<String, dynamic> errorData = json.decode(response.body);
      throw Exception('Failed to load route prediction: ${errorData['error'] ?? response.reasonPhrase}');
    }
  }

  // Method to report an accident (Multipart for files)
  static Future<Map<String, dynamic>> reportAccident({
    required BuildContext context,
    required double latitude,
    required double longitude,
    required String incidentType,
    String? description,
    List<String>? mediaFilePaths, // List of file paths
  }) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    String? accessToken = authService.currentUser?.accessToken;

    if (accessToken == null) {
      throw Exception('Authentication required. Please log in.');
    }

    final uri = Uri.parse('$_baseUrl/api/report_accident');
    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $accessToken'
      ..fields['latitude'] = latitude.toString()
      ..fields['longitude'] = longitude.toString()
      ..fields['incident_type'] = incidentType;

    if (description != null) {
      request.fields['description'] = description;
    }

    if (mediaFilePaths != null && mediaFilePaths.isNotEmpty) {
      for (String path in mediaFilePaths) {
        // http.MultipartFile.fromPath requires dart:io. If targeting web,
        // you'll need a different approach (e.g., file_picker package for web)
        // For mobile, this is fine.
        request.files.add(await http.MultipartFile.fromPath('media_files', path));
      }
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        // Attempt token refresh and retry if 401
        print('Received 401 for reportAccident. Attempting to refresh token...');
        final newAccessToken = await authService.refreshAccessToken();
        if (newAccessToken != null) {
          // Retry the request with the new token
          request.headers['Authorization'] = 'Bearer $newAccessToken';
          final retryStreamedResponse = await request.send();
          final retryResponse = await http.Response.fromStream(retryStreamedResponse);
          if (retryResponse.statusCode == 201) {
            return json.decode(retryResponse.body);
          } else {
            throw Exception('Failed to report accident after token refresh: ${retryResponse.statusCode} ${retryResponse.body}');
          }
        } else {
          await authService.logout();
          throw Exception('Session expired. Please log in again.');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Failed to report accident: ${errorData['error'] ?? response.reasonPhrase}');
      }
    } catch (e) {
      print('Error reporting accident: $e');
      rethrow;
    }
  }

// TODO: Add other API methods here (e.g., get user's reported accidents, admin endpoints)
}