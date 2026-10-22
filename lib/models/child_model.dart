import 'device_model.dart';

class ChildModel {
  final String id;
  final String name;
  final DateTime? dateOfBirth;
  final String? avatarUrl;
  final String? notes;
  final bool isActive;
  final String parentId;
  final List<DeviceModel> devices;
  final Map<String, dynamic>? childUser;

  ChildModel({
    required this.id,
    required this.name,
    this.dateOfBirth,
    this.avatarUrl,
    this.notes,
    this.isActive = true,
    required this.parentId,
    this.devices = const [],
    this.childUser,
  });

  factory ChildModel.fromJson(Map<String, dynamic> json) {
    var rawDevices = json['devices'] as List? ?? [];
    List<DeviceModel> devicesList = rawDevices
        .map((d) => DeviceModel.fromJson(d as Map<String, dynamic>))
        .toList();

    return ChildModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.tryParse(json['dateOfBirth']) : null,
      avatarUrl: json['avatarUrl'],
      notes: json['notes'],
      isActive: json['isActive'] ?? true,
      parentId: json['parentId'] ?? '',
      devices: devicesList,
      childUser: json['childUser'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'avatarUrl': avatarUrl,
      'notes': notes,
      'isActive': isActive,
      'parentId': parentId,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChildModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
