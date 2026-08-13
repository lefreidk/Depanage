class Offer {
  final String id;
  final String requestId;
  final String providerId;
  final String providerName;
  final String? driverPhotoUrl;
  final double? rating;
  final String? truckType;
  final String? truckPlate;
  final int? etaMinutes;
  final double price;
  final String status; // pending, accepted, rejected
  final DateTime createdAt;
  final double? distanceKm;

  Offer({
    required this.id,
    required this.requestId,
    required this.providerId,
    required this.providerName,
    this.driverPhotoUrl,
    this.rating,
    this.truckType,
    this.truckPlate,
    this.etaMinutes,
    required this.price,
    required this.status,
    required this.createdAt,
    this.distanceKm,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id']?.toString() ?? '',
      requestId: json['requestId']?.toString() ?? '',
      providerId: json['providerId']?.toString() ?? '',
      providerName: json['providerName'] ?? 'مزود خدمة',
      driverPhotoUrl: json['driverPhotoUrl'],
      rating: (json['rating'] as num?)?.toDouble(),
      truckType: json['truckType'],
      truckPlate: json['truckPlate'],
      etaMinutes: (json['etaMinutes'] as num?)?.toInt(),
      price: (json['price'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requestId': requestId,
      'providerId': providerId,
      'providerName': providerName,
      'driverPhotoUrl': driverPhotoUrl,
      'rating': rating,
      'truckType': truckType,
      'truckPlate': truckPlate,
      'etaMinutes': etaMinutes,
      'price': price,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'distanceKm': distanceKm,
    };
  }
}
