class AlertModel {
  final String id;
  final String type;
  final String status;
  final String title;
  final String message;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? resolvedAt;
  final String? deviceName;
  final String? childName;

  AlertModel({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    required this.message,
    required this.createdAt,
    this.readAt,
    this.resolvedAt,
    this.deviceName,
    this.childName,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    String? devName;
    String? cName;
    if (json['device'] != null) {
      devName = json['device']['name'];
      if (json['device']['childProfile'] != null) {
        cName = json['device']['childProfile']['name'];
      }
    }

    return AlertModel(
      id: json['id'] ?? '',
      type: json['type'] ?? 'OTHER',
      status: json['status'] ?? 'UNREAD',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt']) : null,
      resolvedAt: json['resolvedAt'] != null ? DateTime.tryParse(json['resolvedAt']) : null,
      deviceName: devName,
      childName: cName,
    );
  }
}
