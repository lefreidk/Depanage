class TowRequestModel {
  final String id;
  final String vehicleCategory;
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final double price;
  String status; // pending | accepted | in_progress | completed | cancelled
  final DateTime createdAt;
  final String? providerName;
  final String? providerPlate;
  final double? rating;

  TowRequestModel({
    required this.id,
    required this.vehicleCategory,
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

  factory TowRequestModel.fromJson(Map<String, dynamic> json) {
    return TowRequestModel(
      id: json['id']?.toString() ?? '',
      vehicleCategory: json['vehicleCategory'] ?? json['vehicle_category'] ?? 'car',
      pickupLat: (json['pickupLat'] ?? json['pickup_lat'] ?? 0).toDouble(),
      pickupLng: (json['pickupLng'] ?? json['pickup_lng'] ?? 0).toDouble(),
      dropoffLat: (json['dropoffLat'] ?? json['dropoff_lat'] ?? 0).toDouble(),
      dropoffLng: (json['dropoffLng'] ?? json['dropoff_lng'] ?? 0).toDouble(),
      price: (json['price'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      createdAt: DateTime.tryParse(json['createdAt'] ?? json['created_at'] ?? '') ?? DateTime.now(),
      providerName: json['providerName'] ?? json['provider_name'],
      providerPlate: json['providerPlate'] ?? json['provider_plate'],
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }
}

class OfferModel {
  final String id;
  final String requestId;
  final String providerId;
  final String providerName;
  final double? rating;
  final String? truckType;
  final String? truckPlate;
  final int? etaMinutes;
  final double price;
  final String status;
  final double? distanceKm;

  OfferModel({
    required this.id,
    required this.requestId,
    required this.providerId,
    required this.providerName,
    this.rating,
    this.truckType,
    this.truckPlate,
    this.etaMinutes,
    required this.price,
    required this.status,
    this.distanceKm,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['offerId']?.toString() ?? json['id']?.toString() ?? '',
      requestId: json['requestId']?.toString() ?? '',
      providerId: json['providerId']?.toString() ?? '',
      providerName: json['providerName'] ?? 'مزود خدمة',
      rating: (json['rating'] as num?)?.toDouble(),
      truckType: json['truckType'],
      truckPlate: json['truckPlate'],
      etaMinutes: (json['etaMinutes'] as num?)?.toInt(),
      price: (json['price'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }
}
