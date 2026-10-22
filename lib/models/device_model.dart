class DeviceModel {
  final String id;
  final String name;
  final String deviceIdentifier;
  final String platform;
  final String status;
  final bool isActive;
  final DateTime? lastSeenAt;
  final String? childProfileId;

  DeviceModel({
    required this.id,
    required this.name,
    required this.deviceIdentifier,
    required this.platform,
    required this.status,
    this.isActive = true,
    this.lastSeenAt,
    this.childProfileId,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      deviceIdentifier: json['deviceIdentifier'] ?? '',
      platform: json['platform'] ?? 'ANDROID',
      status: json['status'] ?? 'UNPAIRED',
      isActive: json['isActive'] ?? true,
      lastSeenAt: json['lastSeenAt'] != null ? DateTime.tryParse(json['lastSeenAt']) : null,
      childProfileId: json['childProfileId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'deviceIdentifier': deviceIdentifier,
      'platform': platform,
      'status': status,
      'isActive': isActive,
      'lastSeenAt': lastSeenAt?.toIso8601String(),
      'childProfileId': childProfileId,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
