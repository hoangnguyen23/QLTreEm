import '../config/api_config.dart';
import '../models/device_model.dart';
import 'api_service.dart';

class DeviceService {
  static Future<List<DeviceModel>> getDevices() async {
    final res = await ApiService.get(ApiConfig.devicesUrl);
    final list = (res['data'] as List?) ?? [];
    return list.map((item) => DeviceModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  static Future<DeviceModel> getDeviceById(String id) async {
    final res = await ApiService.get('${ApiConfig.devicesUrl}/$id');
    final data = res['data'] ?? res;
    return DeviceModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<DeviceModel> updateDevice({
    required String id,
    String? name,
    String? status,
  }) async {
    final res = await ApiService.patch(
      '${ApiConfig.devicesUrl}/$id',
      {
        // ignore: use_null_aware_elements
        if (name != null) 'name': name.trim(),
        // ignore: use_null_aware_elements
        if (status != null) 'status': status,
      },
    );
    final data = res['data'] ?? res;
    return DeviceModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> deleteDevice(String id) async {
    await ApiService.delete('${ApiConfig.devicesUrl}/$id');
  }
}
