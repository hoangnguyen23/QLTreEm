class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? address;
  final bool emailVerified;
  final Map<String, dynamic>? childProfile;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.address,
    this.emailVerified = false,
    this.childProfile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'PARENT',
      phone: json['phone'],
      address: json['address'],
      emailVerified: json['emailVerified'] ?? false,
      childProfile: json['childProfile'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'address': address,
      'emailVerified': emailVerified,
      'childProfile': childProfile,
    };
  }
}
