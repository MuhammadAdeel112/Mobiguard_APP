import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/auth_providers.dart';
import '../../../core/constants/constants.dart';
import '../../../core/helpers.dart';
import '../wallet_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_ui.dart';
import '../../../shared/widgets/app_scaffold.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  void _showPermissionDenied() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You do not have permission to submit top-up requests'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showTopupBottomSheet(BuildContext context, bool canTopup) {
    if (!canTopup) {
      _showPermissionDenied();
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TopupRequestSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);
    final user = ref.watch(authProvider).user;
    final canTopup = user?.hasPermission(AppPermissions.walletTopupCreate) ?? false;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      appBar: ReferenceAppBar.preferred(context, title: 'My Wallet Ledger'),
      body: ReferenceBodyClip(
        child: RefreshIndicator(
          onRefresh: () => ref.read(walletProvider.notifier).fetchWallet(),
          child: walletState.when(
            data: (wallet) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 4,
                        child: Container(
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            gradient: AppTheme.accentGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'AVAILABLE BALANCE',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                Helpers.formatCurrency(wallet.balance),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () => _showTopupBottomSheet(context, canTopup),
                                icon: const Icon(Icons.add_photo_alternate_outlined),
                                label: const Text('Submit Top-up Request'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppTheme.secondaryColor,
                                  minimumSize: const Size(double.infinity, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                      child: Text(
                        'Transaction History',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (wallet.transactions.isEmpty)
                    SliverToBoxAdapter(
                      child: EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No transactions yet',
                        subtitle: 'Top-up requests and enrollment debits will show here.',
                        actionLabel: canTopup ? 'Submit Top-up' : null,
                        onAction: canTopup ? () => _showTopupBottomSheet(context, canTopup) : null,
                      ),
                    )
                  else
                    ..._buildGroupedTransactions(wallet.transactions),
                  SliverPadding(
                    padding: EdgeInsets.only(bottom: AppScaffold.fabOverlapClearance),
                  ),
                ],
              );
            },
            loading: () => const ListSkeleton(itemCount: 4),
            error: (err, _) => EmptyState(
              icon: Icons.error_outline,
              title: 'Could not load wallet',
              subtitle: err.toString(),
              actionLabel: 'Retry',
              onAction: () => ref.read(walletProvider.notifier).fetchWallet(),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGroupedTransactions(List<TransactionModel> transactions) {
    final groups = <String, List<TransactionModel>>{};
    for (final tx in transactions) {
      final label = Helpers.groupDateLabel(tx.date);
      groups.putIfAbsent(label, () => []).add(tx);
    }

    final widgets = <Widget>[];
    for (final entry in groups.entries) {
      widgets.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, AppSpacing.sm, 20, AppSpacing.sm),
            child: Text(
              entry.key,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      );
      widgets.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final tx = entry.value[index];
                final isCredit = tx.type == 'Credit';
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radius),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCredit
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      child: Icon(
                        isCredit ? Icons.south_west : Icons.north_east,
                        color: isCredit ? Colors.green : Colors.red,
                        size: 18,
                      ),
                    ),
                    title: Text(tx.source, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(
                      Helpers.formatDateTime(tx.date),
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isCredit ? "+" : "-"}${Helpers.formatCurrency(tx.amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCredit ? Colors.green : Colors.red,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        StatusChip.fromStatus(tx.status),
                      ],
                    ),
                  ),
                );
              },
              childCount: entry.value.length,
            ),
          ),
        ),
      );
    }
    return widgets;
  }
}

// Modal bottom sheet form for uploading top-ups
class TopupRequestSheet extends ConsumerStatefulWidget {
  const TopupRequestSheet({super.key});

  @override
  ConsumerState<TopupRequestSheet> createState() => _TopupRequestSheetState();
}

class _TopupRequestSheetState extends ConsumerState<TopupRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  File? _selectedImage;
  bool _isSubmitting = false;

  static const _presets = [500.0, 1000.0, 2000.0, 5000.0];

  void _selectPreset(double amount) {
    _amountController.text = amount.toStringAsFixed(0);
    setState(() {});
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to select image: $e')),
      );
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a receipt screenshot'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final amount = double.parse(_amountController.text.trim());
      await ref.read(walletProvider.notifier).requestTopup(amount, _selectedImage!.path);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Top-up request submitted for approval!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Top-up failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Wallet Top-up Request',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => context.pop(),
                  )
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Submit bank transfer or deposit receipts for manual audit approval. Once confirmed, funds will appear in your ledger.',
                style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _presets.map((amount) {
                  return ActionChip(
                    label: Text('Rs. ${amount.toStringAsFixed(0)}'),
                    onPressed: () => _selectPreset(amount),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Deposit Amount (PKR)',
                  prefixIcon: Icon(Icons.monetization_on_outlined),
                  hintText: '0.00',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter deposit amount';
                  }
                  final amount = double.tryParse(val.trim());
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Image Picker Block
              const Text(
                'Receipt Screenshot',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _selectedImage == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'Tap to upload screenshot',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(_selectedImage!, fit: BoxFit.cover),
                              Positioned(
                                right: 8,
                                top: 8,
                                child: CircleAvatar(
                                  backgroundColor: Colors.black.withValues(alpha: 0.6),
                                  radius: 16,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                                    onPressed: _pickImage,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Submit Request'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
