import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../firebase_options.dart';
import '../../features/notifications/notifications_providers.dart';

/// Top-level background message handler for Firebase Cloud Messaging (FCM).
/// This MUST be a top-level function or annotated with @pragma('vm:entry-point')
/// to work in background/terminated isolates.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already done in the background isolate
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  if (kDebugMode) {
    print('FCM Background message received: ${message.messageId}');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');
  }
}

class FirebaseService {
  final Ref _ref;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _clickSubscription;

  FirebaseService(this._ref);

  /// Initialize Firebase Core and background handler.
  /// This should be called in main() before runApp().
  static Future<void> initializeCore() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Set the background messaging handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      if (kDebugMode) {
        print('Firebase Core initialized successfully.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Firebase Core: $e');
      }
    }
  }

  /// Initialize FCM listeners, request permissions, and fetch token.
  /// Call this when the app starts inside the UI initialization.
  Future<void> initNotifications() async {
    // 1. Request Notification Permissions
    await requestPermissions();

    // 2. Fetch & Monitor FCM Token
    await getFcmToken();
    _messaging.onTokenRefresh.listen((newToken) {
      if (kDebugMode) {
        print('FCM Token Refreshed: $newToken');
      }
      // TODO: Send new token to Laravel API when backend connection is set up
    });

    // 3. Foreground Message Listener
    _foregroundSubscription?.cancel();
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('FCM Foreground message received: ${message.messageId}');
      }
      
      // Refresh notifications from backend when a push arrives
      _ref.read(notificationsProvider.notifier).fetchNotifications(isRefresh: true);
    });

    // 4. Terminated state click handler (App was closed completely)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(initialMessage);
    }

    // 5. Background state click handler (App was in background/minimized)
    _clickSubscription?.cancel();
    _clickSubscription = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message);
    });
  }

  /// Request permissions for iOS and Android 13+
  Future<void> requestPermissions() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      if (kDebugMode) {
        print('User notification permission status: ${settings.authorizationStatus}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting notification permissions: $e');
      }
    }
  }

  /// Retrieve the current FCM Registration Token
  Future<String?> getFcmToken() async {
    try {
      final token = await _messaging.getToken();
      if (kDebugMode) {
        print('====================================================');
        print('FCM REGISTRATION TOKEN:');
        print(token);
        print('====================================================');
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching FCM token: $e');
      }
      return null;
    }
  }

  /// Route the user when they tap on a notification.
  void _handleNotificationClick(RemoteMessage message) {
    if (kDebugMode) {
      print('Notification clicked: ${message.notification?.title}');
    }
    
    // Extract routing info if present in message payload (e.g. data: {'route': '/wallet'})
    final route = message.data['route'] as String?;
    if (route != null && route.isNotEmpty) {
      // TODO: Perform deep linking/navigation to specified route
      // e.g., router.go(route);
    }
  }

  /// Dispose listeners to prevent memory leaks.
  void dispose() {
    _foregroundSubscription?.cancel();
    _clickSubscription?.cancel();
  }
}

/// Riverpod provider for the FirebaseService
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  final service = FirebaseService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});
