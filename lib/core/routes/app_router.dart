import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/customers/customers_providers.dart';
import '../../features/customers/presentation/customer_list_screen.dart';
import '../../features/customers/presentation/create_customer_screen.dart';
import '../../features/customers/presentation/customer_detail_screen.dart';
import '../../features/contracts/presentation/contract_list_screen.dart';
import '../../features/contracts/presentation/contract_detail_screen.dart';
import '../../features/enrollment/presentation/enrollment_screen.dart';
import '../../features/enrollment/presentation/qr_display_screen.dart';
import '../../features/wallet/presentation/wallet_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/splash_screen.dart';

import 'dart:async';

// Helper class to trigger GoRouter refreshes on Riverpod provider changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    // Redirect logic based on Auth State
    redirect: (context, state) {
      final status = authState.status;
      final isSplash = state.matchedLocation == '/splash';
      final isLogin = state.matchedLocation == '/login';

      if (status == AuthStatus.initial) {
        return isSplash ? null : '/splash';
      }

      if (status == AuthStatus.unauthenticated) {
        return isLogin ? null : '/login';
      }

      if (status == AuthStatus.authenticated) {
        if (isSplash || isLogin) return '/';
        return null;
      }

      return null;
    },
    // Listen to changes in authProvider
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authProvider.notifier).stream,
    ),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      // Bottom navigation shell
      ShellRoute(
        builder: (context, state, child) {
          return AppScaffold(
            currentPath: state.matchedLocation,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/customers',
            builder: (context, state) => const CustomerListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const CreateCustomerScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final idStr = state.pathParameters['id'] ?? '';
                  final id = int.tryParse(idStr) ?? 0;
                  final customer = state.extra as CustomerModel?;
                  return CustomerDetailScreen(customerId: id, customer: customer);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/contracts',
            builder: (context, state) => const ContractListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final idStr = state.pathParameters['id'] ?? '';
                  final id = int.tryParse(idStr) ?? 0;
                  return ContractDetailScreen(contractId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/enrollment',
            builder: (context, state) => const EnrollmentScreen(),
            routes: [
              GoRoute(
                path: 'verify/:id',
                builder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  final qrPayload = state.uri.queryParameters['qr_payload'] ?? '';
                  return QrDisplayScreen(enrollmentId: id, qrPayload: qrPayload);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/wallet',
            builder: (context, state) => const WalletScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
