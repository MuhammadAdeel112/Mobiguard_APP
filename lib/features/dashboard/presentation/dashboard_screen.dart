import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../auth/auth_providers.dart';
import '../../../core/constants/constants.dart';
import '../../../core/helpers.dart';
import '../../../core/theme/app_theme.dart';
import '../../customers/customers_providers.dart';
import '../../contracts/contracts_providers.dart';
import '../../enrollment/enrollment_providers.dart';
import '../../wallet/wallet_providers.dart';
import '../../notifications/notifications_providers.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_ui.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _showPermissionDenied(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You do not have permission for this action'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatTxDate(DateTime date) {
    return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(walletProvider);
    final customerState = ref.watch(customerListProvider);
    final contractState = ref.watch(contractsProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final user = ref.watch(authProvider).user;
    final agentCode = user?.agentCode ?? 'MG-0000';

    final canCreateCustomer = user?.hasPermission(AppPermissions.customersCreate) ?? false;
    final canEnroll = user?.hasPermission(AppPermissions.enrollmentsCreate) ?? false;
    final canViewContracts = user?.hasPermission(AppPermissions.contractsView) ?? false;
    final canTopup = user?.hasPermission(AppPermissions.walletTopupCreate) ?? false;

    final enrollmentCountAsync = ref.watch(enrollmentCountProvider);

    String statValue(int total, bool isLoading) {
      if (isLoading && total == 0) return '…';
      return '$total';
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      appBar: ReferenceAppBar.preferred(
        context,
        title: 'MobiGuard Sales',
        subtitle: 'Code: $agentCode',
        actions: [
          IconButton(
            icon: Badge(
              label: Text('$unreadCount'),
              isLabelVisible: unreadCount > 0,
              child: const Icon(Icons.notifications_outlined, color: Colors.white),
            ),
            onPressed: () => context.push('/notifications'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ReferenceBodyClip(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              ref.read(walletProvider.notifier).fetchWallet(),
              ref.read(notificationsProvider.notifier).fetchNotifications(isRefresh: true),
              ref.read(customerListProvider.notifier).fetchCustomers(isRefresh: true),
              ref.read(contractsProvider.notifier).fetchContracts(isRefresh: true),
            ]);
            ref.invalidate(enrollmentCountProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md + AppScaffold.fabOverlapClearance,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WalletBalanceCard(
                    walletState: walletState,
                    canTopup: canTopup,
                    onTopup: canTopup
                        ? () => context.go('/wallet')
                        : () => _showPermissionDenied(context),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const SectionTitle(title: 'Quick Actions'),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 1.15,
                    children: [
                      QuickActionTile(
                        icon: Icons.person_add_alt_1,
                        label: 'Add Customer',
                        subtitle: 'Register new customer',
                        background: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF2563EB),
                        enabled: canCreateCustomer,
                        onTap: canCreateCustomer
                            ? () => context.push('/customers/create')
                            : () => _showPermissionDenied(context),
                      ),
                      QuickActionTile(
                        icon: Icons.verified_user_outlined,
                        label: 'New Enrollment',
                        subtitle: 'Start new enrollment',
                        background: const Color(0xFFECFDF5),
                        iconColor: const Color(0xFF059669),
                        enabled: canEnroll,
                        onTap: canEnroll
                            ? () => context.go('/enrollment')
                            : () => _showPermissionDenied(context),
                      ),
                      QuickActionTile(
                        icon: Icons.description_outlined,
                        label: 'Contracts',
                        subtitle: 'View all contracts',
                        background: const Color(0xFFFFFBEB),
                        iconColor: const Color(0xFFD97706),
                        enabled: canViewContracts,
                        onTap: canViewContracts
                            ? () => context.push('/contracts')
                            : () => _showPermissionDenied(context),
                      ),
                      QuickActionTile(
                        icon: Icons.notifications_active_outlined,
                        label: 'Alerts',
                        subtitle: 'Important notifications',
                        background: const Color(0xFFF5F3FF),
                        iconColor: const Color(0xFF7C3AED),
                        onTap: () => context.push('/notifications'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const SectionTitle(title: 'Overview'),
                  Card(
                    elevation: 0,
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Row(
                        children: [
                          StatTile(
                            icon: Icons.people_outline,
                            label: 'Customers',
                            value: statValue(customerState.total, customerState.isLoading),
                            color: const Color(0xFF2563EB),
                            onTap: () => context.go('/customers'),
                          ),
                          Container(height: 52, width: 1, color: Colors.grey.shade200),
                          StatTile(
                            icon: Icons.assignment_outlined,
                            label: 'Enrollments',
                            value: enrollmentCountAsync.when(
                              data: (count) => statValue(count, false),
                              loading: () => '…',
                              error: (e, st) => '—',
                            ),
                            color: const Color(0xFF059669),
                            onTap: () => context.go('/enrollment'),
                          ),
                          Container(height: 52, width: 1, color: Colors.grey.shade200),
                          StatTile(
                            icon: Icons.article_outlined,
                            label: 'Contracts',
                            value: statValue(contractState.total, contractState.isLoading),
                            color: const Color(0xFFD97706),
                            onTap: () => context.push('/contracts'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SectionTitle(
                    title: 'Recent Transactions',
                    trailing: TextButton(
                      onPressed: () => context.go('/wallet'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'View All',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  walletState.when(
                    data: (w) {
                      final recentTxs = w.transactions.take(3).toList();
                      if (recentTxs.isEmpty) {
                        return EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'No transactions yet',
                          subtitle: 'Wallet activity will appear here after top-ups or enrollments.',
                          actionLabel: canTopup ? 'Go to Wallet' : null,
                          onAction: canTopup ? () => context.go('/wallet') : null,
                        );
                      }
                      return Column(
                        children: recentTxs.map((tx) {
                          final isCredit = tx.type == 'Credit';
                          return Container(
                            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: 4,
                              ),
                              leading: CircleAvatar(
                                radius: 22,
                                backgroundColor: isCredit
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFFEF2F2),
                                child: Icon(
                                  isCredit ? Icons.south_west : Icons.north_east,
                                  color: isCredit
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFDC2626),
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                tx.source,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              subtitle: Text(
                                _formatTxDate(tx.date),
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${isCredit ? '+' : '-'}${Helpers.formatCurrency(tx.amount)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isCredit
                                          ? const Color(0xFF059669)
                                          : const Color(0xFFDC2626),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  StatusChip.fromStatus(tx.status, filled: true),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const ListSkeleton(itemCount: 3, itemHeight: 72),
                    error: (err, _) => EmptyState(
                      icon: Icons.error_outline,
                      title: 'Could not load transactions',
                      subtitle: err.toString(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletBalanceCard extends StatelessWidget {
  final AsyncValue<WalletState> walletState;
  final bool canTopup;
  final VoidCallback onTopup;

  const _WalletBalanceCard({
    required this.walletState,
    required this.canTopup,
    required this.onTopup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WALLET BALANCE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    walletState.when(
                      data: (w) => Text(
                        Helpers.formatCurrency(w.balance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      loading: () => const SizedBox(
                        height: 38,
                        width: 38,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      error: (err, _) => Text(
                        Helpers.formatCurrency(0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Available Balance',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 30,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: onTopup,
              icon: Icon(
                Icons.add,
                size: 20,
                color: canTopup ? AppTheme.primaryColor : Colors.grey,
              ),
              label: Text(
                'Top-up Wallet',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: canTopup ? AppTheme.primaryColor : Colors.grey,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryColor,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.6),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
