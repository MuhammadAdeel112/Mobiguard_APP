import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/di/global_providers.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/firebase_service.dart';

void main() async {
  // Ensure Flutter engine is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load SharedPreferences ahead of time for Riverpod injection overrides
  final sharedPrefs = await SharedPreferences.getInstance();

  // Initialize Firebase Core
  await FirebaseService.initializeCore();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      child: const MobiGuardApp(),
    ),
  );
}

class MobiGuardApp extends ConsumerStatefulWidget {
  const MobiGuardApp({super.key});

  @override
  ConsumerState<MobiGuardApp> createState() => _MobiGuardAppState();
}

class _MobiGuardAppState extends ConsumerState<MobiGuardApp> {
  @override
  void initState() {
    super.initState();
    // Initialize Firebase Cloud Messaging (permissions, tokens, listeners)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(firebaseServiceProvider).initNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'MobiGuard Sales',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system, // Dynamically follow phone's dark mode setting
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
