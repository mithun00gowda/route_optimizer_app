// lib/services/api_services.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:optiroute/constants/strings.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart'; // Needed for BuildContext
import '../models/models.dart';
import '../services/auth_service.dart' hide User; // Import AuthService

class ApiService {
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
      throw Exception('Authentication required. Please log in.');
    }

    final Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
      ...?headers,
    };

    final baseUrl = await StringsData.getBaseUrl();
    Uri uri = Uri.parse('$baseUrl$endpoint');
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

      if (response.statusCode == 401) {
        print('Received 401. Attempting to refresh token...');
        final newAccessToken = await authService.refreshAccessToken();
        if (newAccessToken != null) {
          print('Token refreshed, retrying request...');
          requestHeaders['Authorization'] = 'Bearer $newAccessToken';
          if (method == 'POST') {
            response = await http.post(uri,
                headers: requestHeaders, body: json.encode(body));
          } else if (method == 'GET') {
            response = await http.get(uri, headers: requestHeaders);
          } else if (method == 'PUT') {
            response = await http.put(uri,
                headers: requestHeaders, body: json.encode(body));
          } else if (method == 'DELETE') {
            response = await http.delete(uri, headers: requestHeaders);
          }
        } else {
          print('Token refresh failed. Logging out user.');
          await authService.logout();
          throw Exception('Session expired. Please log in again.');
        }
      }

      return response;
    } catch (e) {
      print('Network request error: $e');
      rethrow;
    }
  }

  // --- API Endpoints ---

  static Future<RoutePredictionResult> getRoutePrediction({
    required BuildContext context,
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
      throw Exception(
          'Failed to load route prediction: ${errorData['error'] ?? response.reasonPhrase}');
    }
  }

  static Future<Map<String, dynamic>> reportAccident({
    required BuildContext context,
    required double latitude,
    required double longitude,
    required String incidentType,
    String? description,
    List<String>? mediaFilePaths,
  }) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    String? accessToken = authService.currentUser?.accessToken;

    if (accessToken == null) {
      throw Exception('Authentication required. Please log in.');
    }

    final baseUrl = await StringsData.getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/report_accident');
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
        request.files
            .add(await http.MultipartFile.fromPath('media_files', path));
      }
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        print(
            'Received 401 for reportAccident. Attempting to refresh token...');
        final newAccessToken = await authService.refreshAccessToken();
        if (newAccessToken != null) {
          request.headers['Authorization'] = 'Bearer $newAccessToken';
          final retryStreamedResponse = await request.send();
          final retryResponse =
          await http.Response.fromStream(retryStreamedResponse);
          if (retryResponse.statusCode == 201) {
            return json.decode(retryResponse.body);
          } else {
            throw Exception(
                'Failed to report accident after token refresh: ${retryResponse.statusCode} ${retryResponse.body}');
          }
        } else {
          await authService.logout();
          throw Exception('Session expired. Please log in again.');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            'Failed to report accident: ${errorData['error'] ?? response.reasonPhrase}');
      }
    } catch (e) {
      print('Error reporting accident: $e');
      rethrow;
    }
  }

  static Future<List<ReportedAccident>> getCurrentUserReportedAccidents(
      BuildContext context) async {
    final response = await _sendAuthenticatedRequest(
      context,
      'GET',
      '/api/reported_accidents/mine',
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ReportedAccident.fromJson(json)).toList();
    } else {
      final Map<String, dynamic> errorData = json.decode(response.body);
      throw Exception(
          'Failed to load user reported accidents: ${errorData['error'] ?? response.reasonPhrase}');
    }
  }

  static Future<String> getMediaFileUrl(String mediaPath) async {
    final baseUrl = await StringsData.getBaseUrl();
    return '$baseUrl/api/$mediaPath';
  }

  // --- Admin API Methods ---

  static Future<AdminDashboardOverview> getAdminDashboardOverview(
      BuildContext context) async {
    final response = await _sendAuthenticatedRequest(
      context,
      'GET',
      '/admin/dashboard/overview',
    );
    if (response.statusCode == 200) {
      return AdminDashboardOverview.fromJson(json.decode(response.body));
    } else {
      final errorData = json.decode(response.body);
      throw Exception(
          'Failed to load dashboard overview: ${errorData['msg'] ?? response.reasonPhrase}');
    }
  }

  static Future<List<User>> getAllUsers(BuildContext context) async {
    final response = await _sendAuthenticatedRequest(
      context,
      'GET',
      '/admin/users',
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return (data['users'] as List)
          .map((json) => User.fromJson(json))
          .toList();
    } else {
      final errorData = json.decode(response.body);
      throw Exception(
          'Failed to load users: ${errorData['msg'] ?? response.reasonPhrase}');
    }
  }

  static Future<Map<String, dynamic>> updateUserRole(
      BuildContext context, String publicId, String newRole) async {
    final response = await _sendAuthenticatedRequest(
      context,
      'PUT',
      '/admin/users/$publicId',
      body: {'role': newRole},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(
          'Failed to update user role: ${errorData['message'] ?? response.reasonPhrase}');
    }
  }

  static Future<Map<String, dynamic>> deleteUser(
      BuildContext context, String publicId) async {
    final response = await _sendAuthenticatedRequest(
      context,
      'DELETE',
      '/admin/users/$publicId',
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(
          'Failed to delete user: ${errorData['message'] ?? response.reasonPhrase}');
    }
  }

  static Future<List<AdminReportedAccident>> getAllReportedAccidents(
      BuildContext context) async {
    final response = await _sendAuthenticatedRequest(
      context,
      'GET',
      '/admin/reported_accidents',
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return (data['reported_accidents'] as List)
          .map((json) => AdminReportedAccident.fromJson(json))
          .toList();
    } else {
      final errorData = json.decode(response.body);
      throw Exception(
          'Failed to load all reported accidents: ${errorData['msg'] ?? response.reasonPhrase}');
    }
  }

  static Future<Map<String, dynamic>> updateReportedAccidentStatus(
      BuildContext context, int accidentId, String newStatus) async {
    final response = await _sendAuthenticatedRequest(
      context,
      'PUT',
      '/admin/reported_accidents/$accidentId',
      body: {'status': newStatus},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(
          'Failed to update accident status: ${errorData['message'] ?? response.reasonPhrase}');
    }
  }

  static Future<Map<String, dynamic>> deleteReportedAccident(
      BuildContext context, int accidentId) async {
    final response = await _sendAuthenticatedRequest(
      context,
      'DELETE',
      '/admin/reported_accidents/$accidentId',
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(
          'Failed to delete reported accident: ${errorData['message'] ?? response.reasonPhrase}');
    }
  }

  static Future<List<TravelRate>> getUserTravelRates(
      BuildContext context) async {
    final response = await _sendAuthenticatedRequest(
      context,
      'GET',
      '/admin/travel_analysis/user_rates',
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => TravelRate.fromJson(json)).toList();
    } else {
      final errorData = json.decode(response.body);
      throw Exception(
          'Failed to load user travel rates: ${errorData['msg'] ?? response.reasonPhrase}');
    }
  }

  static Future<List<DailyTrip>> getDailyTrips(BuildContext context) async {
    final response = await _sendAuthenticatedRequest(
      context,
      'GET',
      '/admin/travel_analysis/daily_trips',
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => DailyTrip.fromJson(json)).toList();
    } else {
      final errorData = json.decode(response.body);
      throw Exception(
          'Failed to load daily trips: ${errorData['msg'] ?? response.reasonPhrase}');
    }
  }
}