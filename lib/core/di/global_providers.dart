import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../api/interceptors.dart';

// Secure Storage Provider
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
});

// SharedPreferences Provider (must be overridden in main.dart)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences has not been initialized');
});

// Dio Client Provider
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  final secureStorage = ref.watch(secureStorageProvider);
  
  dio.interceptors.add(AuthInterceptor(secureStorage: secureStorage));
  dio.interceptors.add(LogInterceptor(
    requestHeader: true,
    requestBody: true,
    responseHeader: false,
    responseBody: true,
    error: true,
  ));
  
  return dio;
});

// ApiClient Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(dio);
});
