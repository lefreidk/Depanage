import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // التحقق من حالة تسجيل الدخول عند فتح التطبيق
  Future<void> checkLoginStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final savedUser = StorageService.getUser();
      if (savedUser != null) {
        _user = savedUser;
      }
    } catch (e) {
      _error = 'فشل جلب بيانات المستخدم';
    }

    _isLoading = false;
    notifyListeners();
  }

  // تسجيل دخول المستخدم بعد التحقق الناجح
  Future<void> loginUser(User user) async {
    _user = user;
    await StorageService.saveUser(user);
    await StorageService.setLoggedIn(true);
    notifyListeners();
  }

  // تسجيل الخروج
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await AuthService.logout();
    _user = null;
    _isLoading = false;
    notifyListeners();
  }

  // تحديث الملف الشخصي (الاسم والبريد)
  Future<void> updateProfile({
    required String name,
    required String email,
  }) async {
    if (_user == null) return;

    _isLoading = true;
    notifyListeners();

    final updatedUser = User(
      id: _user!.id,
      phone: _user!.phone,
      name: name,
      email: email,
      avatarUrl: _user!.avatarUrl,
    );

    _user = updatedUser;
    await StorageService.saveUser(updatedUser);

    _isLoading = false;
    notifyListeners();
  }
}
