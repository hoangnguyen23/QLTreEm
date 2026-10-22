import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const String _biometricTokenKey = 'saved_biometric_token';

  // Kiểm tra thiết bị có hỗ trợ cảm biến sinh trắc học không
  static Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (_) {
      return false;
    }
  }

  // Quét vân tay / sinh trắc học trên thiết bị

  static Future<bool> authenticateBiometric({
    String reason = 'Xác thực vân tay để tiếp tục',
  }) async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      final available = await _auth.getAvailableBiometrics();

      debugPrint('Can check biometrics: $canCheck');
      debugPrint('Device supported: $supported');
      debugPrint('Available biometrics: $available');

      final authenticated = await _auth.authenticate(localizedReason: reason);

      debugPrint('Authentication result: $authenticated');
      return authenticated;
    } catch (e, stackTrace) {
      debugPrint('Biometric exception: $e');
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }

  // Kiểm tra tài khoản đã kích hoạt và có token vân tay cục bộ chưa
  static Future<bool> isBiometricEnabledLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_biometricTokenKey);
    return token != null && token.isNotEmpty;
  }

  // Bật đăng nhập vân tay
  static Future<void> enableBiometric() async {
    // 1. Quét vân tay để xác thực người dùng thật
    final authenticated = await authenticateBiometric(
      reason: 'Quét vân tay để bật tính năng đăng nhập nhanh',
    );
    if (!authenticated) {
      throw Exception('Xác thực vân tay không thành công');
    }

    // 2. Gọi API backend lấy biometricToken
    final res = await ApiService.post('${ApiConfig.biometricUrl}/enable', {});
    final biometricToken = res['biometricToken'] as String?;

    if (biometricToken == null || biometricToken.isEmpty) {
      throw Exception('Không nhận được mã xác thực sinh trắc học từ máy chủ');
    }

    // 3. Lưu token vào bộ nhớ thiết bị
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_biometricTokenKey, biometricToken);
  }

  // Tắt đăng nhập vân tay
  static Future<void> disableBiometric() async {
    try {
      await ApiService.post('${ApiConfig.biometricUrl}/disable', {});
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_biometricTokenKey);
  }

  // Đăng nhập nhanh bằng vân tay
  static Future<UserModel> loginWithBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_biometricTokenKey);

    if (token == null || token.isEmpty) {
      throw Exception(
        'Tính năng đăng nhập vân tay chưa được kích hoạt trên thiết bị này',
      );
    }

    // 1. Quét vân tay
    final authenticated = await authenticateBiometric(
      reason: 'Quét vân tay để đăng nhập vào tài khoản',
    );
    if (!authenticated) {
      throw Exception('Xác thực vân tay không thành công');
    }

    // 2. Gửi token lên backend
    final res = await ApiService.post('${ApiConfig.biometricUrl}/login', {
      'biometricToken': token,
    }, withAuth: false);

    final data = res['data'] ?? res;
    final userJson = data['user'] as Map<String, dynamic>;
    final accessToken = data['accessToken'] as String;
    final refreshToken = data['refreshToken'] as String;

    await ApiService.saveSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: userJson,
    );

    return UserModel.fromJson(userJson);
  }
}
