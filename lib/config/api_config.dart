import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String defaultBaseUrl = 'http://192.168.1.5:3000';
  static const String _baseUrlKey = 'custom_base_url';

  static String _baseUrl = defaultBaseUrl;

  static String get baseUrl => _baseUrl;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_baseUrlKey) ?? defaultBaseUrl;
  }

  static Future<void> setBaseUrl(String url) async {
    _baseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, _baseUrl);
  }

  static String get authUrl => '$_baseUrl/api/auth';
  static String get usersUrl => '$_baseUrl/api/users';
  static String get childrenUrl => '$_baseUrl/api/children';
  static String get devicesUrl => '$_baseUrl/api/devices';
  static String get pairingsUrl => '$_baseUrl/api/pairings';
  static String get locationsUrl => '$_baseUrl/api/locations';
  static String get safeZonesUrl => '$_baseUrl/api/safezones';
  static String get alertsUrl => '$_baseUrl/api/alerts';
  static String get biometricUrl => '$_baseUrl/api/biometric';
}
