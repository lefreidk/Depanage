import '../../../core/network/api_client.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/utils/result.dart';
import '../../../models/user_model.dart';

class AuthResult {
  final UserModel user;
  final String token;
  AuthResult(this.user, this.token);
}

/// مستودع المصادقة — طبقة وسيطة بين الشاشات وعميل REST.
/// الشاشات لا تعرف شيئاً عن مسارات الـ API، فقط تستدعي دوال بأسماء واضحة.
class AuthRepository {
  final _api = ApiClient.instance;

  Future<Result<void>> sendOtp(String phoneE164) {
    return _api.post<void>(
      '/api/auth/send-otp',
      body: {'phone': phoneE164},
      withAuth: false,
      parser: (_) {},
    );
  }

  Future<Result<AuthResult>> verifyOtp(String phoneE164, String otp) async {
    final result = await _api.post<AuthResult>(
      '/api/auth/verify-otp',
      body: {'phone': phoneE164, 'otp': otp},
      withAuth: false,
      parser: (json) => AuthResult(
        UserModel.fromJson(json),
        json['token'] as String,
      ),
    );

    if (result case Success(data: final data)) {
      await TokenStorage.saveToken(data.token);
    }
    return result;
  }

  Future<Result<UserModel>> fetchMe() {
    return _api.get<UserModel>('/api/users/me', parser: (json) => UserModel.fromJson(json));
  }

  Future<void> logout() async {
    await TokenStorage.clear();
  }
}
