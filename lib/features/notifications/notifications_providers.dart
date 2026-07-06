import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/global_providers.dart';
import '../../core/constants/constants.dart';

class NotificationModel {
  final int id;
  final String title;
  final String body;
  final bool read;
  final String type;
  final String severity; // 'success', 'warning', 'error', 'info'
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.read,
    required this.type,
    required this.severity,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      title: json['title']?.toString() ?? 'Notification',
      body: json['body']?.toString() ?? '',
      // API returns read_at (null = unread, date string = read)
      read: json['read_at'] != null,
      type: json['type']?.toString() ?? '',
      severity: json['severity']?.toString() ?? 'info',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  NotificationModel copyWith({bool? read}) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      read: read ?? this.read,
      type: type,
      severity: severity,
      createdAt: createdAt,
    );
  }
}

class NotificationListState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final int page;
  final bool hasReachedMax;
  final bool isLoading;
  final String? error;

  NotificationListState({
    required this.notifications,
    required this.unreadCount,
    required this.page,
    required this.hasReachedMax,
    required this.isLoading,
    this.error,
  });

  factory NotificationListState.initial() => NotificationListState(
        notifications: [],
        unreadCount: 0,
        page: 1,
        hasReachedMax: false,
        isLoading: false,
      );

  NotificationListState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    int? page,
    bool? hasReachedMax,
    bool? isLoading,
    String? error,
  }) {
    return NotificationListState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      page: page ?? this.page,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationListState> {
  final Ref _ref;

  NotificationsNotifier(this._ref) : super(NotificationListState.initial()) {
    fetchNotifications();
  }

  Future<void> fetchNotifications({bool isRefresh = false}) async {
    if (state.isLoading) return;
    if (!isRefresh && state.hasReachedMax) return;

    final targetPage = isRefresh ? 1 : state.page;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.get(
        ApiPaths.notifications,
        queryParameters: {
          'page': targetPage,
          'per_page': 20,
        },
      );

      final responseData = response.data;
      
      // Handle both direct list and wrapped {success, data, meta} format
      final List rawData;
      if (responseData is Map) {
        rawData = (responseData['data'] as List?) ?? [];
      } else if (responseData is List) {
        rawData = responseData;
      } else {
        rawData = [];
      }

      final unreadCount = (responseData is Map) 
          ? (responseData['unread_count'] as int? ?? 0) 
          : 0;
      final meta = (responseData is Map) 
          ? responseData['meta'] as Map<String, dynamic>? 
          : null;
      final currentLastPage = meta != null ? (meta['last_page'] as int? ?? 1) : 1;

      final fetchedNotifications = rawData
          .whereType<Map<String, dynamic>>()
          .map((json) => NotificationModel.fromJson(json))
          .toList();

      state = state.copyWith(
        isLoading: false,
        notifications: isRefresh ? fetchedNotifications : [...state.notifications, ...fetchedNotifications],
        unreadCount: unreadCount,
        page: targetPage + 1,
        hasReachedMax: targetPage >= currentLastPage,
      );
    } catch (e) {
      // ignore: avoid_print
      print('🔴 NOTIFICATION ERROR: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAsRead(int id) async {
    // Optimistic UI update
    state = state.copyWith(
      notifications: state.notifications.map((n) => n.id == id ? n.copyWith(read: true) : n).toList(),
      unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
    );

    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.patch('${ApiPaths.notifications}/$id/read');
    } catch (_) {
      // Revert if needed, but for now just ignore
    }
  }

  void addMockNotification(String title, String body) {
    final newNotif = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: body,
      read: false,
      type: 'info',
      severity: 'info',
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      notifications: [newNotif, ...state.notifications],
      unreadCount: state.unreadCount + 1,
    );
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, NotificationListState>((ref) {
  return NotificationsNotifier(ref);
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).unreadCount;
});
