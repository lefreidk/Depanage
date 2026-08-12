import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class StorageService {
  static late SharedPreferences _prefs;

  // تهيئة التخزين المحلي (يُستدعى مرة واحدة عند بدء التطبيق)
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // حفظ المستخدم بعد تسجيل الدخول
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

  // التحقق من تسجيل الدخول
  static bool get isLoggedIn => _prefs.getBool('is_logged_in') ?? false;

  // تعيين حالة تسجيل الدخول
  static Future<void> setLoggedIn(bool value) async {
    await _prefs.setBool('is_logged_in', value);
  }

  // مسح جميع البيانات (تسجيل الخروج)
  static Future<void> clear() async {
    await _prefs.clear();
  }
}
