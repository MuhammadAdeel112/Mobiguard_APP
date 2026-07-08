import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/di/global_providers.dart';
import '../../core/constants/constants.dart';
import '../../core/error/exceptions.dart';
import '../wallet/wallet_providers.dart';
import '../notifications/notifications_providers.dart';

int extractListTotal(Map<String, dynamic> responseData, int fallback) {
  final meta = responseData['meta'];
  if (meta is Map && meta['total'] != null) {
    return meta['total'] as int;
  }
  if (responseData['total'] != null) {
    return responseData['total'] as int;
  }
  return fallback;
}

// Response from POST /enrollment-requests
class EnrollmentModel {
  final int enrollmentRequestId;
  final String token;
  final DateTime expiresAt;
  final Map<String, dynamic> qrPayload;

  EnrollmentModel({
    required this.enrollmentRequestId,
    required this.token,
    required this.expiresAt,
    required this.qrPayload,
  });

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

/// Total enrollment count from backend (GET /enrollment-requests meta.total).
final enrollmentCountProvider = FutureProvider<int>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get(
    ApiPaths.enrollmentRequests,
    queryParameters: {'page': 1, 'per_page': 1},
  );
  final responseData = response.data as Map<String, dynamic>;
  return extractListTotal(responseData, 0);
});

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
        final apiClient = ref.read(apiClientProvider);
        final response = await apiClient.get(
          '${ApiPaths.enrollmentRequests}/$enrollmentId/status',
        );

        final newStatus = response.data['status']?.toString() ?? 'Pending';

        if (state.value != newStatus) {
          state = AsyncValue.data(newStatus);
        }

        final normalized = newStatus.toLowerCase();
        if (normalized == 'approved' || normalized == 'rejected') {
          _timer?.cancel();
          await Future.wait([
            ref.read(walletProvider.notifier).fetchWallet(),
            ref.read(notificationsProvider.notifier).fetchNotifications(isRefresh: true),
          ]);
          ref.invalidate(enrollmentCountProvider);
        }
      } catch (_) {
        // Retry on next poll tick
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
