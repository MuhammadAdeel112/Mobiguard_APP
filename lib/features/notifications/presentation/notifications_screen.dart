import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../notifications_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_ui.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(notificationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(notificationsProvider.notifier).fetchNotifications(isRefresh: true),
        child: notificationsState.isLoading && notificationsState.notifications.isEmpty
            ? const ListSkeleton(itemCount: 6, itemHeight: 88)
            : notificationsState.error != null && notificationsState.notifications.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      EmptyState(
                        icon: Icons.error_outline,
                        title: 'Could not load notifications',
                        subtitle: notificationsState.error,
                        actionLabel: 'Retry',
                        onAction: () =>
                            ref.read(notificationsProvider.notifier).fetchNotifications(isRefresh: true),
                      ),
                    ],
                  )
                : notificationsState.notifications.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          EmptyState(
                            icon: Icons.notifications_none,
                            title: 'No notifications yet',
                            subtitle: 'Alerts about enrollments, wallet, and system updates will appear here.',
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
                        itemCount: notificationsState.notifications.length,
                        itemBuilder: (context, index) {
                          final notif = notificationsState.notifications[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radius),
                              side: BorderSide(
                                color: notif.read ? Colors.grey.shade200 : AppTheme.primaryColor.withValues(alpha: 0.25),
                              ),
                            ),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (!notif.read)
                                    Container(
                                      width: 4,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                                      ),
                                    ),
                                  Expanded(
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: AppSpacing.sm,
                                      ),
                                      leading: CircleAvatar(
                                        backgroundColor: notif.read
                                            ? Colors.grey.shade200
                                            : AppTheme.primaryColor.withValues(alpha: 0.1),
                                        child: Icon(
                                          notif.read ? Icons.notifications_none : Icons.notifications_active,
                                          color: notif.read ? Colors.grey : AppTheme.primaryColor,
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        notif.title,
                                        style: TextStyle(
                                          fontWeight: notif.read ? FontWeight.w500 : FontWeight.bold,
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
                                              color: notif.read ? Colors.grey.shade600 : theme.colorScheme.onSurface,
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
                                      onTap: () {
                                        if (!notif.read) {
                                          ref.read(notificationsProvider.notifier).markAsRead(notif.id);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
