class Offer {
  final String id;
  final String requestId;
  final String providerId;
  final String providerName;
  final double price;
  final String status; // pending, accepted, rejected
  final DateTime createdAt;
  final double? distanceKm; // المسافة بين المزود وموقع الطلب

  Offer({
    required this.id,
    required this.requestId,
    required this.providerId,
    required this.providerName,
    required this.price,
    required this.status,
    required this.createdAt,
    this.distanceKm,
  });

  // تحويل من JSON إلى كائن Offer
  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'] ?? '',
      requestId: json['requestId'] ?? '',
      providerId: json['providerId'] ?? '',
      providerName: json['providerName'] ?? 'مزود خدمة',
      price: (json['price'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }

  // تحويل من كائن Offer إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requestId': requestId,
      'providerId': providerId,
      'providerName': providerName,
      'price': price,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'distanceKm': distanceKm,
    };
  }
}
