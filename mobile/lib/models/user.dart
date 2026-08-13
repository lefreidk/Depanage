class User {
  final String id;
  final String phone;
  final String name;
  final String? email;
  final String? avatarUrl;

  User({
    required this.id,
    required this.phone,
    this.name = '',
    this.email,
    this.avatarUrl,
  });

  // تحويل من JSON إلى كائن User
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      phone: json['phone'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      avatarUrl: json['avatarUrl'],
    );
  }

  // تحويل من كائن User إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
    };
  }

  // نسخة معدلة من المستخدم (للتحديث السريع)
  User copyWith({
    String? id,
    String? phone,
    String? name,
    String? email,
    String? avatarUrl,
  }) {
    return User(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
