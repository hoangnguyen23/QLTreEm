import 'package:geolocator/geolocator.dart';
import '../config/api_config.dart';
import '../models/location_model.dart';
import 'api_service.dart';

class LocationService {
  // Lấy vị trí thực tế của thiết bị thông qua Geolocator
  static Future<Position?> getCurrentDevicePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  // Thiết bị trẻ gửi tọa độ GPS lên backend
  static Future<Map<String, dynamic>> reportLocation({
    required String deviceId,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? speed,
    double? altitude,
  }) async {
    final res = await ApiService.post(
      ApiConfig.locationsUrl,
      {
        'deviceId': deviceId,
        'latitude': latitude,
        'longitude': longitude,
        // ignore: use_null_aware_elements
        if (accuracy != null) 'accuracy': accuracy,
        // ignore: use_null_aware_elements
        if (speed != null) 'speed': speed,
        // ignore: use_null_aware_elements
        if (altitude != null) 'altitude': altitude,
        'recordedAt': DateTime.now().toUtc().toIso8601String(),
      },
    );
    return res['data'] as Map<String, dynamic>;
  }

  // Phụ huynh xem tọa độ mới nhất của thiết bị
  static Future<LocationModel?> getLatestLocation(String deviceId) async {
    final res = await ApiService.get('${ApiConfig.locationsUrl}/device/$deviceId/latest');
    final data = res['data'] ?? res;
    if (data['latestLocation'] != null) {
      return LocationModel.fromJson(data['latestLocation'] as Map<String, dynamic>);
    }
    return null;
  }

  // Phụ huynh xem lịch sử di chuyển
  static Future<List<LocationModel>> getLocationHistory(String deviceId, {int limit = 50}) async {
    final res = await ApiService.get('${ApiConfig.locationsUrl}/device/$deviceId/history?limit=$limit');
    final data = res['data'] ?? res;
    final list = (data['history'] as List?) ?? [];
    return list.map((item) => LocationModel.fromJson(item as Map<String, dynamic>)).toList();
  }
}
