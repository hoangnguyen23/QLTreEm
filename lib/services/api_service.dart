import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userRoleKey = 'user_role';
  static const String _userJsonKey = 'user_data';

  static String? _cachedToken;

  static Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    return _cachedToken;
  }

  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> user,
  }) async {
    _cachedToken = accessToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_userRoleKey, user['role'] ?? 'PARENT');
    await prefs.setString(_userJsonKey, jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userJsonKey);
    if (raw != null) {
      try {
        return jsonDecode(raw);
      } catch (_) {}
    }
    return null;
  }

  static Future<String?> getSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  static Future<void> clearSession() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userJsonKey);
  }

  static Future<Map<String, String>> _getHeaders({bool withAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Future<dynamic> get(String url, {bool withAuth = true}) async {
    try {
      final headers = await _getHeaders(withAuth: withAuth);
      final response = await http.get(Uri.parse(url), headers: headers);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Lỗi kết nối máy chủ: $e');
    }
  }

  static Future<dynamic> post(String url, Map<String, dynamic> body, {bool withAuth = true}) async {
    try {
      final headers = await _getHeaders(withAuth: withAuth);
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Lỗi kết nối máy chủ: $e');
    }
  }

  static Future<dynamic> patch(String url, Map<String, dynamic> body, {bool withAuth = true}) async {
    try {
      final headers = await _getHeaders(withAuth: withAuth);
      final response = await http.patch(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Lỗi kết nối máy chủ: $e');
    }
  }

  static Future<dynamic> delete(String url, {bool withAuth = true}) async {
    try {
      final headers = await _getHeaders(withAuth: withAuth);
      final response = await http.delete(Uri.parse(url), headers: headers);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Lỗi kết nối máy chủ: $e');
    }
  }

  static dynamic _handleResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      String message = 'Đã có lỗi xảy ra (${response.statusCode})';
      if (body is Map) {
        if (body.containsKey('message')) {
          message = body['message'].toString();
        }
        if (body.containsKey('errors') && body['errors'] is List) {
          final errList = (body['errors'] as List)
              .map((e) => e is Map ? (e['message'] ?? e['path']?.toString() ?? e.toString()) : e.toString())
              .join(', ');
          if (errList.isNotEmpty) {
            message = '$message: $errList';
          }
        }
      }
      throw Exception(message);
    }
  }
}
