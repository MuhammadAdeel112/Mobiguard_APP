import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/constants.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;
  AuthInterceptor({
    required FlutterSecureStorage secureStorage,
  })  : _secureStorage = secureStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.read(key: StorageKeys.token);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept'] = 'application/json';
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // In a real app, you would trigger a logout state or token refresh.
      // E.g., _ref.read(authStateProvider.notifier).logout();
    }
    super.onError(err, handler);
  }
}
