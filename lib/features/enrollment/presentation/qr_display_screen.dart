import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../enrollment_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_ui.dart';

class QrDisplayScreen extends ConsumerStatefulWidget {
  final String enrollmentId;
  final String qrPayload;

  const QrDisplayScreen({
    super.key,
    required this.enrollmentId,
    required this.qrPayload,
  });

  @override
  ConsumerState<QrDisplayScreen> createState() => _QrDisplayScreenState();
}

class _QrDisplayScreenState extends ConsumerState<QrDisplayScreen> {
  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }

  String get _elapsedLabel {
    final m = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _copyEnrollmentId() async {
    await Clipboard.setData(ClipboardData(text: widget.enrollmentId));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enrollment ID copied'), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _handleBack(String status) async {
    final normalized = status.toLowerCase();
    if (normalized == 'approved' || normalized == 'rejected') {
      context.go('/enrollment');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Verification?'),
        content: const Text(
          'Enrollment is still in progress. Leaving will stop status tracking. Continue?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Stay')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) context.go('/enrollment');
  }

  @override
  Widget build(BuildContext context) {
    final statusState = ref.watch(enrollmentStatusProvider(widget.enrollmentId));
    final theme = Theme.of(context);
    final status = statusState.asData?.value ?? 'Pending';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack(status);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Device Verification'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _handleBack(status),
          ),
        ),
        body: statusState.when(
          data: (currentStatus) {
            final normalized = currentStatus.toLowerCase();
            final isPending = normalized == 'pending';
            final isApproved = normalized == 'approved';
            final isRejected = normalized == 'rejected';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isApproved
                        ? 'Verification Approved!'
                        : (isRejected ? 'Enrollment Rejected' : 'Scan Activation QR'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isApproved
                          ? Colors.green
                          : (isRejected
                              ? Colors.redAccent
                              : theme.brightness == Brightness.light
                                  ? AppTheme.primaryColor
                                  : Colors.white),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Enrollment ID: ${widget.enrollmentId}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _copyEnrollmentId,
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy ID'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: isPending
                          ? QrImageView(
                              data: widget.qrPayload,
                              version: QrVersions.auto,
                              size: 220,
                              gapless: false,
                            )
                          : SizedBox(
                              height: 220,
                              width: 220,
                              child: Icon(
                                isApproved ? Icons.check_circle : Icons.cancel,
                                size: 100,
                                color: isApproved ? Colors.green : Colors.redAccent,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (isPending) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(AppSpacing.radius),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Awaiting device link • $_elapsedLabel',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Ask the customer to open the MobiGuard app and scan this QR code.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ] else if (isApproved) ...[
                    const Text(
                      'Device registered successfully. Contract protection is now active on this IMEI.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.dashboard),
                      label: const Text('Back to Dashboard'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    ),
                  ] else ...[
                    const Text(
                      'Verification failed. Please verify IMEI eligibility or contact support.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/enrollment'),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                    ),
                  ],
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'Polling failed',
            subtitle: err.toString(),
            actionLabel: 'Back to Dashboard',
            onAction: () => context.go('/'),
          ),
        ),
      ),
    );
  }
}
