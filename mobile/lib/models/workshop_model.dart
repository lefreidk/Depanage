class WorkshopModel {
  final String id;
  final String name;
  final String specialty;
  final String phone;
  final double lat;
  final double lng;
  final double rating;

  WorkshopModel({
    required this.id,
    required this.name,
    required this.specialty,
    required this.phone,
    required this.lat,
    required this.lng,
    required this.rating,
  });

  factory WorkshopModel.fromJson(Map<String, dynamic> json) {
    return WorkshopModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      specialty: json['specialty'] ?? '',
      phone: json['phone'] ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
    );
  }
}
