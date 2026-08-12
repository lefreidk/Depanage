import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProvider extends ChangeNotifier {
  Locale _locale = Locale('ar');
  ThemeMode _themeMode = ThemeMode.light;
  bool _isDriverMode = false;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  bool get isDriverMode => _isDriverMode;

  AppProvider() {
    _loadPreferences();
  }

  // تحميل التفضيلات المحفوظة عند تشغيل التطبيق
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final langCode = prefs.getString('language') ?? 'ar';
      final dark = prefs.getBool('dark_mode') ?? false;
      final driverMode = prefs.getBool('driver_mode') ?? false;

      _locale = Locale(langCode);
      _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
      _isDriverMode = driverMode;
      notifyListeners();
    } catch (e) {
      // إذا فشل التحميل نبقى على الإعدادات الافتراضية
      print('فشل تحميل التفضيلات: $e');
    }
  }

  // تغيير اللغة
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', locale.languageCode);
    } catch (e) {
      print('فشل حفظ اللغة: $e');
    }
  }

  // تبديل الوضع الداكن
  Future<void> toggleTheme(bool dark) async {
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', dark);
    } catch (e) {
      print('فشل حفظ الوضع الداكن: $e');
    }
  }

  // تبديل وضع السائق
  Future<void> toggleDriverMode(bool value) async {
    _isDriverMode = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('driver_mode', value);
    } catch (e) {
      print('فشل حفظ وضع السائق: $e');
    }
  }
}
