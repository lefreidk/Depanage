import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../config.dart';
import 'storage_service.dart';

class AuthService {
  static Future<void> sendOtp(String phone) async {
    final response = await http.post(
      Uri.parse('${AppConfig.serverUrl}/api/auth/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );
    if (response.statusCode != 200) {
      throw Exception('فشل إرسال رمز التحقق');
    }
  }

  static Future<User> verifyOtp(String phone, String otp) async {
    final response = await http.post(
      Uri.parse('${AppConfig.serverUrl}/api/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'otp': otp}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = User(id: data['userId'] ?? phone, phone: phone);
      await StorageService.saveUser(user);
      await StorageService.setLoggedIn(true);
      return user;
    } else {
      throw Exception('رمز التحقق غير صحيح');
    }
  }

  static Future<void> logout() async => await StorageService.clear();

  static User? getCurrentUser() => StorageService.getUser();
}
