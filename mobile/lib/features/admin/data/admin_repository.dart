import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app_config.dart';
import '../../../core/utils/result.dart';

/// تخزين منفصل لتوكن الإدارة حتى لا يتعارض مع جلسة العميل/السائق
/// العادية في نفس الجهاز (مفيد أثناء الاختبار خصوصاً).
class AdminTokenStorage {
  static const _key = 'admin_token';

  static Future<void> save(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  static Future<String?> get() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

class AdminRepository {
  Uri _uri(String path) => Uri.parse('${AppConfig.serverUrl}$path');

  Future<Map<String, String>> _headers() async {
    final token = await AdminTokenStorage.get();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Result<String>> login(String username, String password) async {
    final res = await http.post(
      _uri('/api/auth/admin-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    final decoded = jsonDecode(res.body);

    if (res.statusCode == 200) {
      await AdminTokenStorage.save(decoded['token']);
      return Result.success(decoded['token'] as String);
    }
    return Result.failure(AppFailure.validation(decoded['error'] ?? 'بيانات الدخول غير صحيحة'));
  }

  Future<Result<Map<String, dynamic>>> getStats() => _get('/api/admin/stats');
  Future<Result<List<dynamic>>> getPendingDrivers() => _getList('/api/admin/drivers/pending');
  Future<Result<List<dynamic>>> getApprovedDrivers() => _getList('/api/admin/drivers/approved');
  Future<Result<List<dynamic>>> getClients() => _getList('/api/admin/clients');

  Future<Result<void>> decideDriver(String driverId, String decision) =>
      _post('/api/admin/drivers/decision', {'driverId': driverId, 'decision': decision});

  Future<Result<void>> chargeWallet(String phone, double amount) =>
      _post('/api/admin/wallets/charge', {'phone': phone, 'amount': amount});

  Future<Result<void>> toggleBlockClient(String userId, bool block) =>
      _post('/api/admin/clients/block', {'userId': userId, 'block': block});

  Future<Result<void>> updateSettings(Map<String, dynamic> settings) =>
      _post('/api/admin/settings/update', settings);

  Future<Result<Map<String, dynamic>>> _get(String path) async {
    final res = await http.get(_uri(path), headers: await _headers());
    return _handleMap(res);
  }

  Future<Result<List<dynamic>>> _getList(String path) async {
    final res = await http.get(_uri(path), headers: await _headers());
    if (res.statusCode == 200) return Result.success(jsonDecode(res.body) as List);
    return Result.failure(_failureFor(res));
  }

  Future<Result<void>> _post(String path, Map<String, dynamic> body) async {
    final res = await http.post(_uri(path), headers: await _headers(), body: jsonEncode(body));
    if (res.statusCode >= 200 && res.statusCode < 300) return Result.success(null);
    return Result.failure(_failureFor(res));
  }

  Result<Map<String, dynamic>> _handleMap(http.Response res) {
    if (res.statusCode == 200) return Result.success(jsonDecode(res.body) as Map<String, dynamic>);
    return Result.failure(_failureFor(res));
  }

  AppFailure _failureFor(http.Response res) {
    if (res.statusCode == 401 || res.statusCode == 403) return AppFailure.unauthorized();
    try {
      final decoded = jsonDecode(res.body);
      return AppFailure.server(decoded['error']);
    } catch (_) {
      return AppFailure.server();
    }
  }
}
