import 'package:shared_preferences/shared_preferences.dart';

/// تخزين توكن الجلسة (JWT) بشكل مركزي.
/// ملاحظة: للإنتاج يُفضّل استبدال SharedPreferences بـ flutter_secure_storage
/// لتخزين التوكن في Keychain/Keystore بدل تخزين عادي.
class TokenStorage {
  TokenStorage._();
  static const _key = 'auth_token';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
