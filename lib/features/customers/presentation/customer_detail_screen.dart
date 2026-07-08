import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/auth_providers.dart';
import '../customers_providers.dart';
import '../../../shared/widgets/app_ui.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final int customerId;
  final CustomerModel? customer;

  const CustomerDetailScreen({
    super.key,
    required this.customerId,
    this.customer,
  });

  CustomerModel? _resolveCustomer(WidgetRef ref) {
    if (customer != null) return customer;
    final customers = ref.watch(customerListProvider).customers;
    for (final c in customers) {
      if (c.id == customerId) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider).user;
    final resolved = _resolveCustomer(ref);
    final canEnroll = user?.hasPermission(AppPermissions.enrollmentsCreate) ?? false;

    if (resolved == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer Details')),
        body: EmptyState(
          icon: Icons.person_off_outlined,
          title: 'Customer not found',
          subtitle: 'This customer may have been removed or is not loaded yet.',
          actionLabel: 'Go Back',
          onAction: () => context.pop(),
        ),
      );
    }

    final c = resolved;
    final isActive = c.status.toLowerCase() == 'active';

    return Scaffold(
      appBar: AppBar(title: const Text('Customer Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                      child: Text(
                        c.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 28,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      c.name,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    StatusChip(
                      label: c.status.toUpperCase(),
                      color: isActive ? Colors.green : Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    _DetailRow(icon: Icons.phone_android, label: 'Phone', value: c.phone),
                    const Divider(height: AppSpacing.lg),
                    _DetailRow(
                      icon: Icons.badge_outlined,
                      label: 'CNIC',
                      value: c.cnic.isEmpty ? 'Not provided' : c.cnic,
                    ),
                    const Divider(height: AppSpacing.lg),
                    _DetailRow(
                      icon: Icons.location_on_outlined,
                      label: 'Address',
                      value: c.address.isEmpty ? 'Not provided' : c.address,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (canEnroll)
              ElevatedButton.icon(
                onPressed: () => context.push('/enrollment?customerId=${c.id}'),
                icon: const Icon(Icons.app_registration),
                label: const Text('Start Enrollment'),
              ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(onPressed: () => context.pop(), child: const Text('Back to List')),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}
