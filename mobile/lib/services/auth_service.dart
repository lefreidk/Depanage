import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../config.dart';
import 'storage_service.dart';

class AuthService {
  // إرسال رمز التحقق إلى رقم الهاتف
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

  // التحقق من رمز التحقق وتسجيل الدخول
  static Future<User> verifyOtp(String phone, String otp) async {
    final response = await http.post(
      Uri.parse('${AppConfig.serverUrl}/api/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'otp': otp}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = User.fromJson(data['user']);
      // حفظ المستخدم محليًا
      await StorageService.saveUser(user);
      await StorageService.setLoggedIn(true);
      return user;
    } else {
      throw Exception('رمز التحقق غير صحيح');
    }
  }

  // تسجيل الخروج
  static Future<void> logout() async {
    await StorageService.clear();
  }

  // جلب المستخدم الحالي
  static User? getCurrentUser() {
    return StorageService.getUser();
  }
}
