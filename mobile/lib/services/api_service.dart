import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tow_request.dart';
import '../config.dart';

class ApiService {
  // جلب سجل طلبات المستخدم
  static Future<List<TowRequest>> fetchHistory(String userId) async {
    final response = await http.get(
      Uri.parse('${AppConfig.serverUrl}/api/requests/history?userId=$userId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((json) => TowRequest.fromJson(json)).toList();
    } else {
      throw Exception('فشل جلب سجل الطلبات');
    }
  }

  // إنشاء طلب جديد (اختياري إذا لم نستخدم Socket.IO)
  static Future<TowRequest> createRequest({
    required String userId,
    required String vehicleType,
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    required double price,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.serverUrl}/api/requests/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'vehicleType': vehicleType,
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'dropoffLat': dropoffLat,
        'dropoffLng': dropoffLng,
        'price': price,
      }),
    );

    if (response.statusCode == 200) {
      return TowRequest.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('فشل إنشاء الطلب');
    }
  }

  // تحديث الملف الشخصي
  static Future<void> updateProfile({
    required String userId,
    required String name,
    required String email,
  }) async {
    final response = await http.put(
      Uri.parse('${AppConfig.serverUrl}/api/profile/update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'name': name,
        'email': email,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('فشل تحديث الملف الشخصي');
    }
  }
}
