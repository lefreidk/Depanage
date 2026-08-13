class Trip {
  final String id;
  final String requestId;
  final String driverId;
  final String driverName;
  final String driverPlate;
  final String vehicleCategory;
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final double finalPrice;
  final int rating;
  final String status; // completed, cancelled, in_progress
  final DateTime createdAt;
  final DateTime? completedAt;

  Trip({
    required this.id,
    required this.requestId,
    required this.driverId,
    required this.driverName,
    required this.driverPlate,
    required this.vehicleCategory,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.finalPrice,
    required this.rating,
    required this.status,
    required this.createdAt,
    this.completedAt,
  });

  // تحويل من JSON إلى كائن Trip
  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id']?.toString() ?? '',
      requestId: json['request_id']?.toString() ?? '',
      driverId: json['driver_id']?.toString() ?? '',
      driverName: json['driver_name'] ?? 'غير محدد',
      driverPlate: json['driver_plate'] ?? 'غير محدد',
      vehicleCategory: json['vehicle_category'] ?? 'car',
      pickupLat: (json['pickup_lat'] as num?)?.toDouble() ?? 0,
      pickupLng: (json['pickup_lng'] as num?)?.toDouble() ?? 0,
      dropoffLat: (json['dropoff_lat'] as num?)?.toDouble() ?? 0,
      dropoffLng: (json['dropoff_lng'] as num?)?.toDouble() ?? 0,
      finalPrice: (json['final_price'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      status: json['status'] ?? 'completed',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      completedAt: DateTime.tryParse(json['completed_at'] ?? ''),
    );
  }

  // تحويل من كائن Trip إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_id': requestId,
      'driver_id': driverId,
      'driver_name': driverName,
      'driver_plate': driverPlate,
      'vehicle_category': vehicleCategory,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'dropoff_lat': dropoffLat,
      'dropoff_lng': dropoffLng,
      'final_price': finalPrice,
      'rating': rating,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}
