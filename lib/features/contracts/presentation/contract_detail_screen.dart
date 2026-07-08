import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../auth/auth_providers.dart';
import '../../../core/constants/constants.dart';
import '../contracts_providers.dart';
import '../../../core/theme/app_theme.dart';

class ContractDetailScreen extends ConsumerWidget {
  final int contractId;

  const ContractDetailScreen({
    super.key,
    required this.contractId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(contractDetailProvider(contractId));
    final user = ref.watch(authProvider).user;
    final canEnroll = user?.hasPermission(AppPermissions.enrollmentsCreate) ?? false;
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final monthFormatter = DateFormat('MMMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contract Details'),
      ),
      body: detailState.when(
        data: (contract) {
          final paidCount = contract.installments.where((i) => i.status == 'paid').length;
          final pendingCount = contract.installments.where((i) => i.status == 'pending').length;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header Card ──────────────────────────────────────
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  contract.contractNo,
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              _StatusChip(status: contract.status),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Customer
                          _InfoRow(icon: Icons.person_outline, label: 'Customer', value: contract.customer.name),
                          if (contract.customer.phone != null)
                            _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: contract.customer.phone!),
                          const Divider(height: 24),

                          // Branch
                          _InfoRow(icon: Icons.storefront_outlined, label: 'Branch', value: contract.branch.name),
                          if (contract.branch.branchCode != null)
                            _InfoRow(icon: Icons.tag, label: 'Branch Code', value: contract.branch.branchCode!),
                          const Divider(height: 24),

                          // Financials
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _StatCard(
                                label: 'TOTAL AMOUNT',
                                value: currencyFormatter.format(contract.totalAmount),
                                color: theme.colorScheme.primary,
                              ),
                              _StatCard(
                                label: 'INSTALLMENT',
                                value: currencyFormatter.format(contract.installmentAmount),
                                color: Colors.teal,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _StatCard(label: 'DURATION', value: '${contract.durationMonths} Months', color: Colors.indigo),
                              _StatCard(label: 'START DATE', value: dateFormatter.format(contract.startDate), color: Colors.orange),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Device Card ──────────────────────────────────────
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.phone_android, size: 36, color: Colors.grey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: contract.device == null
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('No Device Enrolled', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                      const Text('Device enrollment is pending for this contract.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Device Enrolled', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                      Text('IMEI: ${contract.device?['imei1'] ?? '-'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                          ),
                          Icon(
                            contract.device == null ? Icons.radio_button_off : Icons.check_circle,
                            color: contract.device == null ? Colors.orange : Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Installments Card ────────────────────────────────
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Installment Schedule',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: [
                                  _PillBadge(label: 'Paid: $paidCount', color: Colors.green),
                                  const SizedBox(width: 6),
                                  _PillBadge(label: 'Due: $pendingCount', color: Colors.orange),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...contract.installments.map((inst) {
                            final isPaid = inst.status == 'paid';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isPaid
                                    ? Colors.green.withValues(alpha: 0.07)
                                    : Colors.orange.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isPaid ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        isPaid ? Icons.check_circle : Icons.schedule,
                                        size: 16,
                                        color: isPaid ? Colors.green : Colors.orange,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        monthFormatter.format(inst.dueDate),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    currencyFormatter.format(inst.amount),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isPaid ? Colors.green : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (contract.device == null && canEnroll)
                    ElevatedButton.icon(
                      onPressed: () => context.push('/enrollment?contractId=${contract.id}'),
                      icon: const Icon(Icons.app_registration),
                      label: const Text('Start Enrollment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  if (contract.device == null && canEnroll) const SizedBox(height: 12),

                  OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Back to List'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('Error: $err', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status.toLowerCase() == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isActive ? Colors.green : Colors.orange).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: isActive ? Colors.green : Colors.orange),
          const SizedBox(width: 5),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: isActive ? Colors.green : Colors.orange,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _PillBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _PillBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
    );
  }
}
