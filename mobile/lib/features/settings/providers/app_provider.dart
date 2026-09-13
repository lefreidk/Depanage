import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isDriverMode = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDriverMode => _isDriverMode;

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final dark = prefs.getBool('dark_mode');
    _themeMode = dark == null ? ThemeMode.system : (dark ? ThemeMode.dark : ThemeMode.light);
    _isDriverMode = prefs.getBool('driver_mode') ?? false;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _themeMode = value ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
  }

  Future<void> setDriverMode(bool value) async {
    _isDriverMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('driver_mode', value);
  }
}
