import '../config/api_config.dart';
import '../models/child_model.dart';
import 'api_service.dart';

class ChildService {
  static Future<List<ChildModel>> getChildren() async {
    final res = await ApiService.get(ApiConfig.childrenUrl);
    final list = (res['data'] as List?) ?? [];
    return list.map((item) => ChildModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  static Future<ChildModel> getChildById(String id) async {
    final res = await ApiService.get('${ApiConfig.childrenUrl}/$id');
    final data = res['data'] ?? res;
    return ChildModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<ChildModel> createChild({
    required String name,
    DateTime? dateOfBirth,
    String? notes,
    String? childEmail,
  }) async {
    final res = await ApiService.post(
      ApiConfig.childrenUrl,
      {
        'name': name.trim(),
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth.toIso8601String().split('T').first,
        if (notes != null && notes.isNotEmpty) 'notes': notes.trim(),
        if (childEmail != null && childEmail.isNotEmpty) 'childEmail': childEmail.trim(),
      },
    );
    final data = res['data'] ?? res;
    return ChildModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<ChildModel> updateChild({
    required String id,
    String? name,
    DateTime? dateOfBirth,
    String? notes,
    bool? isActive,
    String? childEmail,
  }) async {
    final res = await ApiService.patch(
      '${ApiConfig.childrenUrl}/$id',
      {
        // ignore: use_null_aware_elements
        if (name != null) 'name': name.trim(),
        // ignore: use_null_aware_elements
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth.toIso8601String().split('T').first,
        // ignore: use_null_aware_elements
        if (notes != null) 'notes': notes.trim(),
        // ignore: use_null_aware_elements
        if (isActive != null) 'isActive': isActive,
        // ignore: use_null_aware_elements
        if (childEmail != null) 'childEmail': childEmail.trim(),
      },
    );
    final data = res['data'] ?? res;
    return ChildModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> deleteChild(String id) async {
    await ApiService.delete('${ApiConfig.childrenUrl}/$id');
  }
}
