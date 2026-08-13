class Workshop {
  final int id;
  final String name;
  final String specialty;
  final String phone;
  final double lat;
  final double lng;
  final double rating;

  Workshop({
    required this.id,
    required this.name,
    required this.specialty,
    required this.phone,
    required this.lat,
    required this.lng,
    required this.rating,
  });

  // تحويل من JSON إلى كائن Workshop
  factory Workshop.fromJson(Map<String, dynamic> json) {
    return Workshop(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      specialty: json['specialty'] ?? '',
      phone: json['phone'] ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
    );
  }

  // تحويل من كائن Workshop إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'phone': phone,
      'lat': lat,
      'lng': lng,
      'rating': rating,
    };
  }
}
