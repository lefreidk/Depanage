import 'package:flutter/material.dart';
import '../../../core/network/socket_client.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/utils/result.dart';
import '../../../models/user_model.dart';
import '../data/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  AuthProvider({AuthRepository? repository}) : _repository = repository ?? AuthRepository();

  UserModel? _user;
  AuthStatus _status = AuthStatus.unknown;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  AppFailure? _lastError;

  UserModel? get user => _user;
  AuthStatus get status => _status;
  bool get isLoggedIn => _status == AuthStatus.authenticated;
  bool get isSendingOtp => _isSendingOtp;
  bool get isVerifyingOtp => _isVerifyingOtp;
  AppFailure? get lastError => _lastError;

  /// يُستدعى عند إقلاع التطبيق: يتحقق من وجود توكن، ثم يجلب بيانات
  /// المستخدم فعلياً من الخادم (بدل افتراض صلاحية التوكن من مجرد وجوده)،
  /// ويؤسس اتصال Socket فور نجاح التحقق.
  Future<void> bootstrap() async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    final result = await _repository.fetchMe();
    await result.when(
      success: (user) async {
        _user = user;
        _status = AuthStatus.authenticated;
        await SocketClient.instance.connect(user.id);
      },
      failure: (_) async {
        await TokenStorage.clear();
        _status = AuthStatus.unauthenticated;
      },
    );
    notifyListeners();
  }

  Future<bool> sendOtp(String phoneE164) async {
    _isSendingOtp = true;
    _lastError = null;
    notifyListeners();

    final result = await _repository.sendOtp(phoneE164);
    _isSendingOtp = false;

    return result.when(
      success: (_) {
        notifyListeners();
        return true;
      },
      failure: (f) {
        _lastError = f;
        notifyListeners();
        return false;
      },
    );
  }

  Future<bool> verifyOtp(String phoneE164, String otp) async {
    _isVerifyingOtp = true;
    _lastError = null;
    notifyListeners();

    final result = await _repository.verifyOtp(phoneE164, otp);
    _isVerifyingOtp = false;

    return result.when(
      success: (data) async {
        _user = data.user;
        _status = AuthStatus.authenticated;
        await SocketClient.instance.connect(data.user.id);
        notifyListeners();
        return true;
      },
      failure: (f) async {
        _lastError = f;
        notifyListeners();
        return false;
      },
    );
  }

  Future<void> logout() async {
    SocketClient.instance.disconnect();
    await _repository.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
