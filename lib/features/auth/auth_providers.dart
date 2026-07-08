import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/constants.dart';
import '../../core/di/global_providers.dart';
import '../../core/error/exceptions.dart';
import 'domain/user_model.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;

  const AuthState({
    required this.status,
    this.user,
    this.error,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  factory AuthState.unauthenticated({String? error}) =>
      AuthState(status: AuthStatus.unauthenticated, error: error);

  factory AuthState.authenticated(UserModel user) =>
      AuthState(status: AuthStatus.authenticated, user: user);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(AuthState.initial()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final secureStorage = _ref.read(secureStorageProvider);
    final token = await secureStorage.read(key: StorageKeys.token);

    if (token == null || token.isEmpty) {
      state = AuthState.unauthenticated();
      return;
    }

    // Restore cached session immediately so reopening the app does not show login.
    final cachedUser = await _readCachedUser(secureStorage);
    if (cachedUser != null) {
      state = AuthState.authenticated(cachedUser);
    }

    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.get(ApiPaths.me);
      final user = _parseUserFromMeResponse(response.data);
      await _persistSession(secureStorage, user);
      state = AuthState.authenticated(user);
    } on AuthFailure {
      await _clearSession(secureStorage);
      state = AuthState.unauthenticated();
    } on NetworkFailure {
      // Keep the cached session alive when offline — only logout clears it.
      if (cachedUser == null) {
        state = AuthState.unauthenticated(
          error: 'No internet connection. Please try again.',
        );
      }
    } catch (_) {
      if (cachedUser == null) {
        await _clearSession(secureStorage);
        state = AuthState.unauthenticated();
      }
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.post(
        ApiPaths.login,
        data: {'email': email, 'password': password},
      );

      final token = response.data['token'] as String;
      final userJson = response.data['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userJson);

      final secureStorage = _ref.read(secureStorageProvider);
      await secureStorage.write(key: StorageKeys.token, value: token);
      await _persistSession(secureStorage, user);

      state = AuthState.authenticated(user);
    } on Failure catch (e) {
      state = AuthState.unauthenticated(error: e.message);
      throw e;
    } catch (e) {
      state = AuthState.unauthenticated(error: 'An unexpected error occurred');
      throw Failure(e.toString());
    }
  }

  Future<void> logout() async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.post(ApiPaths.logout);
    } catch (_) {
      // Force clean up even if API call fails (e.g., no internet)
    } finally {
      final secureStorage = _ref.read(secureStorageProvider);
      await _clearSession(secureStorage);
      state = AuthState.unauthenticated();
    }
  }

  Future<UserModel?> _readCachedUser(FlutterSecureStorage storage) async {
    final cachedUserJson = await storage.read(key: StorageKeys.user);
    if (cachedUserJson == null || cachedUserJson.isEmpty) return null;

    try {
      return UserModel.fromJson(
        jsonDecode(cachedUserJson) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistSession(FlutterSecureStorage storage, UserModel user) async {
    await storage.write(
      key: StorageKeys.user,
      value: jsonEncode(user.toJson()),
    );
  }

  Future<void> _clearSession(FlutterSecureStorage storage) async {
    await storage.delete(key: StorageKeys.token);
    await storage.delete(key: StorageKeys.user);
  }

  UserModel _parseUserFromMeResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['user'] is Map<String, dynamic>) {
        return UserModel.fromJson(data['user'] as Map<String, dynamic>);
      }
      if (data.containsKey('id') && data.containsKey('email')) {
        return UserModel.fromJson(data);
      }
    }
    throw const Failure('Invalid user response from server');
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
