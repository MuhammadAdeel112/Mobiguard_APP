import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';
import '../../core/di/global_providers.dart';
import '../../core/constants/constants.dart';
import '../../core/error/exceptions.dart';
import '../wallet/wallet_providers.dart';
import '../notifications/notifications_providers.dart';

// Response from POST /enrollment-requests
class EnrollmentModel {
  final int enrollmentRequestId;
  final String token;
  final DateTime expiresAt;
  final Map<String, dynamic> qrPayload; // full JSON object for QR encoding

  EnrollmentModel({
    required this.enrollmentRequestId,
    required this.token,
    required this.expiresAt,
    required this.qrPayload,
  });

  // The QR code must encode the entire qr_payload as a JSON string
  String get qrPayloadString => jsonEncode(qrPayload);

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    return EnrollmentModel(
      enrollmentRequestId: json['enrollment_request_id'] as int,
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      qrPayload: json['qr_payload'] as Map<String, dynamic>,
    );
  }
}

class EnrollmentNotifier extends StateNotifier<AsyncValue<EnrollmentModel?>> {
  final Ref _ref;

  EnrollmentNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<EnrollmentModel> createEnrollment({
    required int customerId,
    required int contractId,
    required String brand,
    required String model,
    required String imei1,
    String imei2 = '',
  }) async {
    state = const AsyncValue.loading();
    try {
      final apiClient = _ref.read(apiClientProvider);

      final Map<String, dynamic> body = {
        'contract_id': contractId,
        'customer_id': customerId,
        'imei_1': imei1,
        'brand': brand,
        'model': model,
      };
      if (imei2.isNotEmpty) body['imei_2'] = imei2;

      final response = await apiClient.post(
        ApiPaths.enrollmentRequests,
        data: body,
      );

      final enrollment = EnrollmentModel.fromJson(response.data);
      state = AsyncValue.data(enrollment);
      return enrollment;
    } catch (e, stack) {
      String msg = 'Failed to create enrollment request';
      if (e is DioException && e.response != null && e.response?.data is Map) {
        msg = e.response?.data['message'] ?? msg;
      }
      final failure = Failure(msg);
      state = AsyncValue.error(failure, stack);
      throw failure;
    }
  }
}

final enrollmentProvider = StateNotifierProvider<EnrollmentNotifier, AsyncValue<EnrollmentModel?>>((ref) {
  return EnrollmentNotifier(ref);
});

// Enrollment Polling Notifier (StateNotifier Family)
class EnrollmentStatusNotifier extends StateNotifier<AsyncValue<String>> {
  final String enrollmentId;
  final Ref ref;
  Timer? _timer;

  EnrollmentStatusNotifier({
    required this.ref,
    required this.enrollmentId,
  }) : super(const AsyncValue.data('Pending')) {
    _startPolling();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final dio = ref.read(dioProvider);
        final response = await dio.get(
          '${AppConfig.baseUrl}${ApiPaths.enrollmentRequests}/$enrollmentId/status',
        );
        
        final newStatus = response.data['status'] as String;
        
        if (state.value != newStatus) {
          state = AsyncValue.data(newStatus);
        }

        if (newStatus == 'Approved' || newStatus == 'Rejected') {
          _timer?.cancel();

          if (newStatus == 'Approved') {
            // Add notification alert
            ref.read(notificationsProvider.notifier).addMockNotification(
              'Enrollment Approved 🎉',
              'Enrollment $enrollmentId has been successfully verified. Device registered.',
            );
            // Deduct $49.99 Standard Protection price
            ref.read(walletProvider.notifier).deductBalance(49.99, 'Enrollment: $enrollmentId');
          } else {
            ref.read(notificationsProvider.notifier).addMockNotification(
              'Enrollment Rejected ❌',
              'Enrollment $enrollmentId verification failed. Device rejected.',
            );
          }
        }
      } catch (e) {
        // Silently log or retry on next tick
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final enrollmentStatusProvider = StateNotifierProvider.family<EnrollmentStatusNotifier, AsyncValue<String>, String>((ref, enrollmentId) {
  return EnrollmentStatusNotifier(ref: ref, enrollmentId: enrollmentId);
});
