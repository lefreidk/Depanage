class DriverApplication {
  final String userId;
  final String fullName;
  final String licenseNumber;
  final String licenseExpiry;
  final String plateNumber;
  final int vehicleYear;
  final List<String> vehicleTypes;
  final Map<String, String> documents; // Base64 strings

  DriverApplication({
    required this.userId,
    required this.fullName,
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.plateNumber,
    required this.vehicleYear,
    required this.vehicleTypes,
    required this.documents,
  });

  // تحويل إلى JSON للإرسال إلى الخادم
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'licenseNumber': licenseNumber,
      'licenseExpiry': licenseExpiry,
      'plateNumber': plateNumber,
      'vehicleYear': vehicleYear,
      'vehicleTypes': vehicleTypes,
      'documents': documents,
    };
  }

  // إنشاء كائن من JSON (إذا لزم)
  factory DriverApplication.fromJson(Map<String, dynamic> json) {
    return DriverApplication(
      userId: json['userId'] ?? '',
      fullName: json['fullName'] ?? '',
      licenseNumber: json['licenseNumber'] ?? '',
      licenseExpiry: json['licenseExpiry'] ?? '',
      plateNumber: json['plateNumber'] ?? '',
      vehicleYear: json['vehicleYear'] ?? 0,
      vehicleTypes: List<String>.from(json['vehicleTypes'] ?? []),
      documents: Map<String, String>.from(json['documents'] ?? {}),
    );
  }
}
