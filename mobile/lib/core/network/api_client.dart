import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/result.dart';
import '../../app_config.dart';
import 'token_storage.dart';

/// عميل REST مركزي — كل استدعاءات الشبكة يجب أن تمر من هنا وليس عبر
/// http.get/post مباشرة داخل الشاشات. المزايا:
/// 1) حقن توكن JWT تلقائياً في كل طلب.
/// 2) معالجة موحّدة للأخطاء (شبكة/انتهاء صلاحية/خادم) عبر Result<T>.
/// 3) تسجيل خروج تلقائي عند استقبال 401 من الخادم.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  Uri _uri(String path) => Uri.parse('${AppConfig.serverUrl}$path');

  Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (withAuth) {
      final token = await TokenStorage.getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    required T Function(dynamic json) parser,
    bool withAuth = true,
  }) async {
    try {
      final uri = _uri(path).replace(
        queryParameters: query?.map((k, v) => MapEntry(k, v.toString())),
      );
      final res = await http.get(uri, headers: await _headers(withAuth: withAuth));
      return _handle(res, parser);
    } on SocketException {
      return Result.failure(AppFailure.network());
    } catch (e) {
      return Result.failure(AppFailure.server(e.toString()));
    }
  }

  Future<Result<T>> post<T>(
    String path, {
    Map<String, dynamic>? body,
    required T Function(dynamic json) parser,
    bool withAuth = true,
  }) async {
    try {
      final res = await http.post(
        _uri(path),
        headers: await _headers(withAuth: withAuth),
        body: jsonEncode(body ?? {}),
      );
      return _handle(res, parser);
    } on SocketException {
      return Result.failure(AppFailure.network());
    } catch (e) {
      return Result.failure(AppFailure.server(e.toString()));
    }
  }

  Future<Result<T>> patch<T>(
    String path, {
    Map<String, dynamic>? body,
    required T Function(dynamic json) parser,
    bool withAuth = true,
  }) async {
    try {
      final res = await http.patch(
        _uri(path),
        headers: await _headers(withAuth: withAuth),
        body: jsonEncode(body ?? {}),
      );
      return _handle(res, parser);
    } on SocketException {
      return Result.failure(AppFailure.network());
    } catch (e) {
      return Result.failure(AppFailure.server(e.toString()));
    }
  }

  Result<T> _handle<T>(http.Response res, T Function(dynamic json) parser) {
    final decoded = res.body.isNotEmpty ? jsonDecode(res.body) : null;

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return Result.success(parser(decoded));
    }

    if (res.statusCode == 401 || res.statusCode == 403) {
      return Result.failure(AppFailure.unauthorized(decoded?['error']));
    }

    if (res.statusCode >= 400 && res.statusCode < 500) {
      return Result.failure(AppFailure.validation(decoded?['error'] ?? 'طلب غير صالح'));
    }

    return Result.failure(AppFailure.server(decoded?['error']));
  }
}
