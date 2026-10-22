import '../config/api_config.dart';
import '../models/safezone_model.dart';
import 'api_service.dart';

class SafeZoneService {
  static Future<List<SafeZoneModel>> getSafeZones({String? childProfileId}) async {
    String url = ApiConfig.safeZonesUrl;
    if (childProfileId != null && childProfileId.isNotEmpty) {
      url += '?childProfileId=$childProfileId';
    }
    final res = await ApiService.get(url);
    final list = (res['data'] as List?) ?? [];
    return list.map((item) => SafeZoneModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  static Future<SafeZoneModel> createSafeZone({
    required String name,
    required double latitude,
    required double longitude,
    required double radius,
    required String childProfileId,
  }) async {
    final res = await ApiService.post(
      ApiConfig.safeZonesUrl,
      {
        'name': name.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        'childProfileId': childProfileId,
      },
    );
    final data = res['data'] ?? res;
    return SafeZoneModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<SafeZoneModel> updateSafeZone({
    required String id,
    String? name,
    double? latitude,
    double? longitude,
    double? radius,
    bool? isActive,
  }) async {
    final res = await ApiService.patch(
      '${ApiConfig.safeZonesUrl}/$id',
      {
        // ignore: use_null_aware_elements
        if (name != null) 'name': name.trim(),
        // ignore: use_null_aware_elements
        if (latitude != null) 'latitude': latitude,
        // ignore: use_null_aware_elements
        if (longitude != null) 'longitude': longitude,
        // ignore: use_null_aware_elements
        if (radius != null) 'radius': radius,
        // ignore: use_null_aware_elements
        if (isActive != null) 'isActive': isActive,
      },
    );
    final data = res['data'] ?? res;
    return SafeZoneModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> deleteSafeZone(String id) async {
    await ApiService.delete('${ApiConfig.safeZonesUrl}/$id');
  }
}
