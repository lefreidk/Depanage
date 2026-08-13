import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class StorageService {
  static late SharedPreferences _prefs;

  // تهيئة التخزين المحلي
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // حفظ بيانات المستخدم
  static Future<void> saveUser(User user) async {
    await _prefs.setString('user_id', user.id);
    await _prefs.setString('user_phone', user.phone);
    await _prefs.setString('user_name', user.name);
    await _prefs.setString('user_email', user.email ?? '');
    await _prefs.setString('user_avatar', user.avatarUrl ?? '');
  }

  // جلب المستخدم المحفوظ
  static User? getUser() {
    final phone = _prefs.getString('user_phone');
    if (phone == null || phone.isEmpty) return null;

    return User(
      id: _prefs.getString('user_id') ?? '',
      phone: phone,
      name: _prefs.getString('user_name') ?? '',
      email: _prefs.getString('user_email'),
      avatarUrl: _prefs.getString('user_avatar'),
    );
  }

  // حفظ حالة تسجيل الدخول
  static Future<void> setLoggedIn(bool value) async {
    await _prefs.setBool('is_logged_in', value);
  }

  // التحقق من تسجيل الدخول
  static bool get isLoggedIn => _prefs.getBool('is_logged_in') ?? false;

  // حفظ مسار صورة الملف الشخصي
  static Future<void> saveAvatarPath(String path) async {
    await _prefs.setString('avatar_path', path);
  }

  // جلب مسار صورة الملف الشخصي
  static String? getAvatarPath() {
    return _prefs.getString('avatar_path');
  }

  // مسح جميع البيانات
  static Future<void> clear() async {
    await _prefs.clear();
  }
}
