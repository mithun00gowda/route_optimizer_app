// lib/constants/strings.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StringsData {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _baseUrlKey = 'base_url';
  static const String _defaultBaseUrl = 'http://172.20.10.2:5001';

  static Future<String> getBaseUrl() async {
    return await _secureStorage.read(key: _baseUrlKey) ?? _defaultBaseUrl;
  }

  static Future<void> setBaseUrl(String newUrl) async {
    await _secureStorage.write(key: _baseUrlKey, value: newUrl);
  }
}