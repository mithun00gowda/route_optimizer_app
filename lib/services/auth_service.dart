import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:optiroute/constants/strings.dart';

// Define a simple User model
class User {
  final String email;
  final String username;
  final String publicId;
  final String role;
  String accessToken; // This will be updated on refresh
  String refreshToken;

  User({
    required this.email,
    required this.username,
    required this.publicId,
    required this.role,
    required this.accessToken,
    required this.refreshToken,
  });

  // Helper to create a new User object with updated token
  User copyWith({
    String? email,
    String? username,
    String? publicId,
    String? role,
    String? accessToken,
    String? refreshToken,
  }) {
    return User(
      email: email ?? this.email,
      username: username ?? this.username,
      publicId: publicId ?? this.publicId,
      role: role ?? this.role,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }
}

class AuthService extends ChangeNotifier {
  // TODO: Replace with your actual backend URL (e.g., 'http://192.168.1.X:5000')
  final String _baseUrl = StringsData.BASE_URL;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  AuthService() {
    _attemptAutoLogin();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: 'jwt_access_token', value: accessToken);
    await _secureStorage.write(key: 'jwt_refresh_token', value: refreshToken);
  }

  Future<void> _deleteTokens() async {
    await _secureStorage.delete(key: 'jwt_access_token');
    await _secureStorage.delete(key: 'jwt_refresh_token');
  }

  Future<Map<String, String?>> _getTokens() async {
    final accessToken = await _secureStorage.read(key: 'jwt_access_token');
    final refreshToken = await _secureStorage.read(key: 'jwt_refresh_token');
    return {'access_token': accessToken, 'refresh_token': refreshToken};
  }

  // Fetches full user details using the access token from the /me endpoint
  Future<User?> _fetchAndSetUser(String accessToken, String refreshToken) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/me'), // Now correctly points to the /me endpoint
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> userData = json.decode(response.body);
        return User(
          email: userData['email'] as String,
          username: userData['username'] as String,
          publicId: userData['public_id'] as String,
          role: userData['role'] as String,
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      } else {
        print('Failed to fetch user details from /me: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching user details from /me: $e');
      return null;
    }
  }

  // Attempts to log in automatically using stored tokens
  Future<void> _attemptAutoLogin() async {
    _setLoading(true);
    final tokens = await _getTokens();
    final accessToken = tokens['access_token'];
    final refreshToken = tokens['refresh_token'];

    if (accessToken != null && refreshToken != null) {
      // Check if access token is expired
      if (JwtDecoder.isExpired(accessToken)) {
        print('Access token expired, attempting to refresh...');
        final newAccessToken = await refreshAccessToken();
        if (newAccessToken == null) {
          print('Failed to refresh token. Logging out.');
          await _deleteTokens();
          _currentUser = null;
          _setLoading(false);
          return;
        }
        // Use the new access token for fetching user details
        final user = await _fetchAndSetUser(newAccessToken, refreshToken);
        if (user != null) {
          _currentUser = user;
          print('Auto-login successful with refreshed token for user: ${_currentUser!.username}');
        } else {
          print('Failed to fetch user details after token refresh. Logging out.');
          await _deleteTokens();
          _currentUser = null;
        }
      } else {
        // Access token is still valid, fetch user details
        final user = await _fetchAndSetUser(accessToken, refreshToken);
        if (user != null) {
          _currentUser = user;
          print('Auto-login successful for user: ${_currentUser!.username}');
        } else {
          print('Failed to fetch user details during auto-login. Logging out.');
          await _deleteTokens();
          _currentUser = null;
        }
      }
    } else {
      print('No tokens found for auto-login.');
    }
    _setLoading(false);
  }

  Future<String?> login(String username, String password) async {
    _setLoading(true);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );
      print("$username,$password");
      print(response.statusCode);
      print(response.body);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print(responseData);
        final String accessToken = responseData['access_token'];
        final String email = responseData['email'];
        final String refreshToken = responseData['refresh_token'];
        final String role = responseData['role'];
        final String username = responseData['username']; // Now available from Flask login
        final String publicId = responseData['public_id']; // Now available from Flask login

        _currentUser = User(
          email: email, // Use provided email from input
          username: username,
          publicId: publicId,
          role: role,
          accessToken: accessToken,
          refreshToken: refreshToken,
        );

        await _saveTokens(accessToken, refreshToken);
        notifyListeners();
        return null; // Login successful
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return errorData['message'] ?? 'Login failed. Please check your credentials.';
      }
    } catch (e) {
      return 'An error occurred during login: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> register(String username, String email, String password) async {
    _setLoading(true);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        notifyListeners();
        return null; // Registration successful
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return errorData['message'] ?? 'Registration failed.';
      }
    } catch (e) {
      return 'An error occurred during registration: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Method to refresh the access token using the refresh token
  Future<String?> refreshAccessToken() async {
    if (_currentUser == null || _currentUser!.refreshToken.isEmpty) {
      print('No refresh token available.');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_currentUser!.refreshToken}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final String newAccessToken = responseData['access_token'];

        // Update current user's access token and save to secure storage
        // Note: Flask-JWT-Extended refresh endpoint only returns new access token, not new refresh token
        _currentUser = _currentUser!.copyWith(accessToken: newAccessToken);
        await _secureStorage.write(key: 'jwt_access_token', value: newAccessToken);

        notifyListeners();
        print('Access token refreshed successfully.');
        return newAccessToken;
      } else {
        print('Failed to refresh token: ${response.statusCode} ${response.body}');
        await _deleteTokens(); // Clear tokens if refresh fails
        _currentUser = null;
        notifyListeners();
        return null;
      }
    } catch (e) {
      print('Error refreshing token: $e');
      await _deleteTokens();
      _currentUser = null;
      notifyListeners();
      return null;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    // In a real app, you might also call a backend logout endpoint here
    _currentUser = null;
    await _deleteTokens();
    notifyListeners();
    _setLoading(false);
  }
}