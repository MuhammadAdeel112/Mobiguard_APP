import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../enrollment_providers.dart';
import '../../../core/theme/app_theme.dart';

class QrDisplayScreen extends ConsumerWidget {
  final String enrollmentId;
  final String qrPayload;

  const QrDisplayScreen({
    super.key,
    required this.enrollmentId,
    required this.qrPayload,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusState = ref.watch(enrollmentStatusProvider(enrollmentId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Verification'),
        automaticallyImplyLeading: false, // Prevent going back midway through polling
      ),
      body: statusState.when(
        data: (status) {
          final isPending = status == 'Pending';
          final isApproved = status == 'Approved';
          final isRejected = status == 'Rejected';

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Headline
                  Text(
                    isApproved ? 'Verification Approved!' : (isRejected ? 'Enrollment Rejected' : 'Scan Activation QR'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isApproved 
                          ? Colors.green 
                          : (isRejected ? Colors.redAccent : theme.brightness == Brightness.light ? AppTheme.primaryColor : Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enrollment Request ID: $enrollmentId',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),

                  // Center QR Code or Status Graphic
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: isPending
                          ? QrImageView(
                              data: qrPayload,
                              version: QrVersions.auto,
                              size: 220.0,
                              gapless: false,
                              errorStateBuilder: (cxt, err) {
                                return const Center(child: Text('Error generating QR Code'));
                              },
                            )
                          : Container(
                              height: 220,
                              width: 220,
                              alignment: Alignment.center,
                              child: Icon(
                                isApproved ? Icons.check_circle : Icons.cancel,
                                size: 100,
                                color: isApproved ? Colors.green : Colors.redAccent,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Polling status indicators
                  if (isPending) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Awaiting customer device link...',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Please open the MobiGuard Client app on the customer\'s smartphone and scan the QR code to finish device configuration.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ] else if (isApproved) ...[
                    const Text(
                      'The device has been successfully registered and active. The standard contract protection is active on this IMEI block.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.dashboard),
                      label: const Text('Back to Dashboard'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Verification was rejected by the server checks. Please review device eligibility status or verify IMEI numbers are correct.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Return to Home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Polling failed: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
