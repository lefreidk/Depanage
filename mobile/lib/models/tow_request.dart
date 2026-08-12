class TowRequest {
  final String id;
  final String vehicleType;
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final double price;
  String status; // <-- أزلنا final
  final DateTime createdAt;
  final String? providerName;
  final String? providerPlate;
  final double? rating;

  TowRequest({
    required this.id,
    required this.vehicleType,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.price,
    required this.status,
    required this.createdAt,
    this.providerName,
    this.providerPlate,
    this.rating,
  });

  factory TowRequest.fromJson(Map<String, dynamic> json) {
    return TowRequest(
      id: json['id'] ?? '',
      vehicleType: json['vehicleType'] ?? 'سيدان',
      pickupLat: (json['pickupLat'] ?? 0).toDouble(),
      pickupLng: (json['pickupLng'] ?? 0).toDouble(),
      dropoffLat: (json['dropoffLat'] ?? 0).toDouble(),
      dropoffLng: (json['dropoffLng'] ?? 0).toDouble(),
      price: (json['price'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      providerName: json['providerName'],
      providerPlate: json['providerPlate'],
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleType': vehicleType,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'dropoffLat': dropoffLat,
      'dropoffLng': dropoffLng,
      'price': price,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'providerName': providerName,
      'providerPlate': providerPlate,
      'rating': rating,
    };
  }
}
