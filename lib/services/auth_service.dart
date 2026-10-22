import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  // Đăng ký tài khoản (Gửi OTP qua email)
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final res = await ApiService.post('${ApiConfig.authUrl}/register', {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
    }, withAuth: false);
    return res is Map<String, dynamic> ? res : {};
  }

  // Xác minh OTP đăng ký
  static Future<Map<String, dynamic>> verifyRegisterOtp({
    required String email,
    required String otp,
  }) async {
    final res = await ApiService.post(
      '${ApiConfig.authUrl}/register/verify-otp',
      {'email': email.trim().toLowerCase(), 'otp': otp.trim()},
      withAuth: false,
    );
    return res is Map<String, dynamic> ? res : {};
  }

  // Đăng nhập (Gửi OTP qua email)
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await ApiService.post('${ApiConfig.authUrl}/login', {
      'email': email.trim().toLowerCase(),
      'password': password,
    }, withAuth: false);
    return res is Map<String, dynamic> ? res : {};
  }

  // Xác minh OTP đăng nhập -> Lấy token
  static Future<UserModel> verifyLoginOtp({
    required String email,
    required String otp,
  }) async {
    final res = await ApiService.post('${ApiConfig.authUrl}/login/verify-otp', {
      'email': email.trim().toLowerCase(),
      'otp': otp.trim(),
    }, withAuth: false);

    final data = res['data'] as Map<String, dynamic>;

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

  // Lấy hồ sơ tài khoản hiện tại
  static Future<UserModel> getProfile() async {
    final res = await ApiService.get('${ApiConfig.usersUrl}/me');
    final data = res['data'] ?? res;
    return UserModel.fromJson(data);
  }

  // Đăng xuất
  static Future<void> logout() async {
    try {
      await ApiService.post('${ApiConfig.authUrl}/logout', {});
    } catch (_) {}
    await ApiService.clearSession();
  }
}
