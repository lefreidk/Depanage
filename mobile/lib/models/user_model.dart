class UserModel {
  final String id;
  final String phone;
  final String name;
  final String role; // client | driver | admin
  final bool blocked;

  const UserModel({
    required this.id,
    required this.phone,
    required this.name,
    this.role = 'client',
    this.blocked = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      phone: json['phone'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'client',
      blocked: json['blocked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'name': name,
        'role': role,
        'blocked': blocked,
      };

  UserModel copyWith({String? name, String? role}) => UserModel(
        id: id,
        phone: phone,
        name: name ?? this.name,
        role: role ?? this.role,
        blocked: blocked,
      );
}
