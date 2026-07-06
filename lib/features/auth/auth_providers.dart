import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    if (token == null) {
      state = AuthState.unauthenticated();
      return;
    }

    try {
      final apiClient = _ref.read(apiClientProvider);
      // GET /me to validate stored token and restore user session
      final response = await apiClient.get(ApiPaths.me);
      
      // API wraps user in {"user": {...}}
      final userJson = response.data['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userJson);
      state = AuthState.authenticated(user);
    } catch (e) {
      // Token is invalid or expired — clean up and show login
      await secureStorage.delete(key: StorageKeys.token);
      state = AuthState.unauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    // Optionally emit a loading state here if you have one, 
    // but typically Riverpod AsyncNotifier handles loading better.
    // For now, we'll keep the current StateNotifier approach.
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.post(
        ApiPaths.login,
        data: {'email': email, 'password': password},
      );

      final token = response.data['token'] as String;
      // API returns user nested inside login response as {token, user}
      final userJson = response.data['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userJson);

      final secureStorage = _ref.read(secureStorageProvider);
      await secureStorage.write(key: StorageKeys.token, value: token);
      
      state = AuthState.authenticated(user);
    } on Failure catch (e) {
      // ApiClient already translates Dio exceptions into Failure subclasses
      // e.g. ValidationFailure, AuthFailure, NetworkFailure
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
      await secureStorage.delete(key: StorageKeys.token);
      state = AuthState.unauthenticated();
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
