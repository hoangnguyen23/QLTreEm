import '../config/api_config.dart';
import '../models/alert_model.dart';
import 'api_service.dart';

class AlertService {
  static Future<Map<String, dynamic>> getAlerts({
    String? status,
    String? type,
    String? childId,
  }) async {
    final queryParams = <String>[];
    if (status != null && status.isNotEmpty) queryParams.add('status=$status');
    if (type != null && type.isNotEmpty) queryParams.add('type=$type');
    if (childId != null && childId.isNotEmpty) queryParams.add('childId=$childId');

    String url = ApiConfig.alertsUrl;
    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }

    final res = await ApiService.get(url);
    final data = res['data'] ?? res;
    final list = (data['alerts'] as List?) ?? [];
    final unreadCount = (data['unreadCount'] as num?)?.toInt() ?? 0;

    return {
      'alerts': list.map((item) => AlertModel.fromJson(item as Map<String, dynamic>)).toList(),
      'unreadCount': unreadCount,
    };
  }

  static Future<Map<String, dynamic>> triggerSos({String? deviceId}) async {
    final res = await ApiService.post(
      '${ApiConfig.alertsUrl}/sos',
      {
        if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
      },
    );
    return res['data'] ?? res;
  }

  static Future<void> markRead(String id) async {
    await ApiService.patch('${ApiConfig.alertsUrl}/$id/read', {});
  }

  static Future<void> markResolved(String id) async {
    await ApiService.patch('${ApiConfig.alertsUrl}/$id/resolve', {});
  }

  static Future<void> deleteAlert(String id) async {
    await ApiService.delete('${ApiConfig.alertsUrl}/$id');
  }
}
