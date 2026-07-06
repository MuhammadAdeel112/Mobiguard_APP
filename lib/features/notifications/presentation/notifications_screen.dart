import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../notifications_providers.dart';
import '../../../core/theme/app_theme.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(notificationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(notificationsProvider.notifier).fetchNotifications(isRefresh: true),
        child: notificationsState.isLoading && notificationsState.notifications.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : notificationsState.error != null && notificationsState.notifications.isEmpty
                ? Center(child: Text('Error loading notifications: ${notificationsState.error}'))
                : notificationsState.notifications.isEmpty
                    ? const Center(child: Text('No notifications yet'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: notificationsState.notifications.length,
                        itemBuilder: (context, index) {
                          final notif = notificationsState.notifications[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                            elevation: 0.5,
                            color: notif.read 
                                ? theme.cardTheme.color 
                                : (theme.brightness == Brightness.light ? Colors.blue.shade50.withValues(alpha: 0.4) : const Color(0xFF1E293B)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: notif.read 
                                    ? Colors.grey.shade200 
                                    : AppTheme.primaryColor.withValues(alpha: 0.1),
                                child: Icon(
                                  notif.read ? Icons.notifications_none : Icons.notifications_active,
                                  color: notif.read ? Colors.grey : AppTheme.primaryColor,
                                ),
                              ),
                              title: Text(
                                notif.title,
                                style: TextStyle(
                                  fontWeight: notif.read ? FontWeight.normal : FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    notif.body,
                                    style: TextStyle(
                                      color: notif.read ? Colors.grey.shade600 : Colors.black87,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    DateFormat('MMM dd, yyyy • hh:mm a').format(notif.createdAt),
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                                  ),
                                ],
                              ),
                              trailing: !notif.read
                                  ? Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  : null,
                              onTap: () {
                                if (!notif.read) {
                                  ref.read(notificationsProvider.notifier).markAsRead(notif.id);
                                }
                              },
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
