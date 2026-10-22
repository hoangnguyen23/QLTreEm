import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class PairingService {
  static const String _childDeviceTokenKey = 'child_device_token';
  static const String _childDeviceIdKey = 'child_device_id';
  static const String _childProfileNameKey = 'child_profile_name';

  // Phụ huynh tạo phiên ghép nối QR cho trẻ
  static Future<Map<String, dynamic>> generatePairing(String childProfileId) async {
    final res = await ApiService.post(
      '${ApiConfig.pairingsUrl}/generate',
      {'childProfileId': childProfileId},
    );
    return res['data'] as Map<String, dynamic>;
  }

  // Phụ huynh kiểm tra trạng thái ghép nối (PENDING -> COMPLETED)
  static Future<String> checkPairingStatus(String pairingId) async {
    final res = await ApiService.get('${ApiConfig.pairingsUrl}/$pairingId/status');
    final data = res['data'] ?? res;
    return data['status'] ?? 'PENDING';
  }

  // Thiết bị trẻ quét QR / nhập mã để hoàn tất ghép nối
  static Future<Map<String, dynamic>> confirmPairing({
    required String token,
    required String deviceIdentifier,
    required String deviceName,
    String platform = 'ANDROID',
    String? childUserId,
  }) async {
    final currentUser = await ApiService.getSavedUser();
    String? effectiveChildUserId = childUserId;
    if (effectiveChildUserId == null && currentUser != null && currentUser['role'] == 'CHILD') {
      effectiveChildUserId = currentUser['id'] as String?;
    }

    final res = await ApiService.post(
      '${ApiConfig.pairingsUrl}/confirm',
      {
        'token': token.trim(),
        'deviceIdentifier': deviceIdentifier.trim(),
        'name': deviceName.trim(),
        'platform': platform,
        // ignore: use_null_aware_elements
        if (effectiveChildUserId != null) 'childUserId': effectiveChildUserId,
      },
      withAuth: false,
    );

    final data = res['data'] ?? res;
    final accessToken = data['accessToken'] as String?;
    final device = data['device'] as Map<String, dynamic>?;
    final childProfile = data['childProfile'] as Map<String, dynamic>?;

    if (accessToken != null && device != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_childDeviceTokenKey, accessToken);
      await prefs.setString(_childDeviceIdKey, device['id'] ?? '');
      await prefs.setString(_childProfileNameKey, childProfile?['name'] ?? 'Bé');

      // Nếu chưa có tài khoản User CHILD đăng nhập, lưu session độc lập của thiết bị
      final currentToken = await ApiService.getToken();
      final currentRole = await ApiService.getSavedRole();
      if (currentToken == null || currentToken.isEmpty || currentRole != 'CHILD') {
        await ApiService.saveSession(
          accessToken: accessToken,
          refreshToken: '',
          user: {
            'id': device['id'],
            'name': device['name'],
            'role': 'CHILD',
            'childProfileId': childProfile?['id'],
          },
        );
      }
    }

    return data;
  }

  // Kiểm tra máy hiện tại đã ghép nối là máy trẻ chưa
  static Future<bool> isChildDevicePaired() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_childDeviceTokenKey);
    return token != null && token.isNotEmpty;
  }

  static Future<Map<String, String>> getChildDeviceSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'deviceId': prefs.getString(_childDeviceIdKey) ?? '',
      'childName': prefs.getString(_childProfileNameKey) ?? '',
    };
  }

  static Future<void> unpairChildDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_childDeviceTokenKey);
    await prefs.remove(_childDeviceIdKey);
    await prefs.remove(_childProfileNameKey);
    await ApiService.clearSession();
  }
}
