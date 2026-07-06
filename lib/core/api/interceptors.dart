import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../constants/constants.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;
  AuthInterceptor({
    required FlutterSecureStorage secureStorage,
  })  : _secureStorage = secureStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.read(key: StorageKeys.token);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept'] = 'application/json';
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // In a real app, you would trigger a logout state or token refresh.
      // E.g., _ref.read(authStateProvider.notifier).logout();
    }
    super.onError(err, handler);
  }
}

class MockInterceptor extends Interceptor {
  final Map<String, int> _enrollmentPollCount = {};

  MockInterceptor();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!AppConfig.useMockData) {
      return handler.next(options);
    }

    final path = options.path;
    // Strip host + optional /api prefix so cleanPath matches ApiPaths constants
    // e.g. "http://127.0.0.1:8000/api/auth/login" → "/auth/login"
    final cleanPath = path
        .replaceFirst(RegExp(r'^https?://[^/]+'), '')
        .replaceFirst(RegExp(r'^/api'), '');
    final method = options.method.toUpperCase();

    // Delay response to simulate network latency
    await Future.delayed(const Duration(milliseconds: 600));

    // Handle Mocks
    try {
      if (cleanPath == ApiPaths.login && method == 'POST') {
        final data = options.data;
        String email = '';
        if (data is Map) {
          email = data['email'] ?? '';
        } else if (data is String) {
          final decoded = jsonDecode(data);
          email = decoded['email'] ?? '';
        }

        if (email == 'error@mobiguard.com') {
          return handler.reject(DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 422,
              data: {
                'message': 'The given data was invalid.',
                'errors': {
                  'email': ['The selected email is invalid.']
                }
              },
            ),
          ));
        }

        return handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'token': 'mock_bearer_token_xyz_123456789',
            'user': {
              'id': 42,
              'company_id': 1,
              'branch_id': 3,
              'name': 'Agent Alexander',
              'email': email.isEmpty ? 'agent@demofinance.test' : email,
              'role': 'sales_agent',
              'phone': '03001234567',
              'permissions': [
                'customers.view',
                'customers.create',
                'contracts.view',
                'contracts.create',
                'contracts.update',
                'enrollments.view',
                'enrollments.create',
                'devices.view',
                'devices.manage_state',
                'wallet.view',
                'wallet_topups.create',
              ],
            }
          },
        ));
      }

      if (cleanPath == ApiPaths.logout && method == 'POST') {
        return handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {'success': true},
        ));
      }

      if (cleanPath == ApiPaths.me && method == 'GET') {
        return handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          // API wraps user in {user: {...}}
          data: {
            'user': {
              'id': 42,
              'company_id': 1,
              'branch_id': 3,
              'name': 'Agent Alexander',
              'email': 'agent@demofinance.test',
              'role': 'sales_agent',
              'phone': '03001234567',
              'permissions': [
                'customers.view',
                'customers.create',
                'contracts.view',
                'contracts.create',
                'contracts.update',
                'enrollments.view',
                'enrollments.create',
                'devices.view',
                'devices.manage_state',
                'wallet.view',
                'wallet_topups.create',
              ],
            }
          },
        ));
      }

      if (cleanPath.startsWith(ApiPaths.customers)) {
        if (method == 'GET') {
          // Pagination and query search
          final queryParams = options.queryParameters;
          final search = queryParams['search']?.toString().toLowerCase() ?? '';
          final page = int.tryParse(queryParams['page']?.toString() ?? '1') ?? 1;
          const limit = 10;

          final allCustomers = List.generate(35, (index) {
            final id = index + 1;
            return {
              'id': id,
              'name': _customerNames[index % _customerNames.length] + (index >= _customerNames.length ? ' ${index ~/ _customerNames.length}' : ''),
              'phone': '+1 (555) 301-00${id.toString().padLeft(2, '0')}',
              'email': 'customer$id@example.com',
              'address': '${100 + id} Business District Dr, Suite $id, Metro City',
              'created_at': DateTime.now().subtract(Duration(days: index)).toIso8601String(),
            };
          });

          final filtered = allCustomers.where((c) {
            final name = c['name'].toString().toLowerCase();
            final phone = c['phone'].toString().toLowerCase();
            final email = c['email'].toString().toLowerCase();
            return name.contains(search) || phone.contains(search) || email.contains(search);
          }).toList();

          final startIndex = (page - 1) * limit;
          final endIndex = startIndex + limit;
          final paged = filtered.sublist(
            startIndex.clamp(0, filtered.length),
            endIndex.clamp(0, filtered.length),
          );

          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'data': paged,
              'current_page': page,
              'last_page': (filtered.length / limit).ceil(),
              'total': filtered.length,
            },
          ));
        }

        if (method == 'POST') {
          final data = options.data is Map ? options.data : jsonDecode(options.data.toString());
          final newId = 100 + DateTime.now().millisecond;
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 201,
            data: {
              'id': newId,
              'name': data['name'] ?? 'New Customer',
              'phone': data['phone'] ?? '+1 (555) 000-0000',
              'email': data['email'] ?? 'new@customer.com',
              'address': data['address'] ?? 'Default Address',
              'created_at': DateTime.now().toIso8601String(),
            },
          ));
        }
      }

      if (cleanPath.startsWith(ApiPaths.contracts) && method == 'GET') {
        if (cleanPath == ApiPaths.contracts) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: _mockContracts,
          ));
        } else {
          // Detail view: match id
          final segments = cleanPath.split('/');
          final contractId = segments.last;
          final matched = _mockContracts.firstWhere(
            (c) => c['id'].toString() == contractId,
            orElse: () => _mockContracts.first,
          );
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: matched,
          ));
        }
      }

      if (cleanPath == ApiPaths.enrollmentRequests && method == 'POST') {
        final data = options.data is Map ? options.data : jsonDecode(options.data.toString());
        final enrollmentId = 'ENR-${DateTime.now().millisecondsSinceEpoch}';
        
        // Initial setup for status polling
        _enrollmentPollCount[enrollmentId] = 0;

        return handler.resolve(Response(
          requestOptions: options,
          statusCode: 201,
          data: {
            'id': enrollmentId,
            'customer_id': data['customer_id'],
            'contract_id': data['contract_id'],
            'brand': data['brand'],
            'model': data['model'],
            'imei_1': data['imei_1'],
            'imei_2': data['imei_2'],
            'status': 'Pending',
            'qr_payload': 'mobiguard://enrollment/$enrollmentId/verify?token=secure_payload_hash_key',
            'created_at': DateTime.now().toIso8601String(),
          },
        ));
      }

      // Check status of enrollment: /api/enrollments/{id}/status
      final statusMatch = RegExp(r'^/api/enrollments/([^/]+)/status$').firstMatch(cleanPath);
      if (statusMatch != null && method == 'GET') {
        final id = statusMatch.group(1) ?? '';
        final count = _enrollmentPollCount[id] ?? 0;
        
        String status = 'Pending';
        if (count >= 2) {
          status = 'Approved';
        } else {
          _enrollmentPollCount[id] = count + 1;
        }

        return handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'id': id,
            'status': status,
            'message': status == 'Approved' 
                ? 'Device registered successfully' 
                : 'Waiting for device activation check...',
          },
        ));
      }

      if (cleanPath == ApiPaths.wallet && method == 'GET') {
        return handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'balance': 1575.50,
            'currency': 'USD',
            'transactions': _mockTransactions,
          },
        ));
      }

      if (cleanPath == ApiPaths.walletTopup && method == 'POST') {
        // Multipart top-up request
        return handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'status': 'success',
            'message': 'Top-up request submitted successfully. Waiting for admin approval.',
            'request': {
              'id': 'TRX-TOP-${DateTime.now().millisecond}',
              'amount': 250.00,
              'status': 'Pending',
              'created_at': DateTime.now().toIso8601String(),
            }
          },
        ));
      }

      if (cleanPath == ApiPaths.notifications && method == 'GET') {
        return handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: _mockNotifications,
        ));
      }

      // Mark notification as read
      final markReadMatch = RegExp(r'^/notifications/(\d+)/read$').firstMatch(cleanPath);
      if (markReadMatch != null && method == 'PATCH') {
        final idStr = markReadMatch.group(1) ?? '';
        final id = int.tryParse(idStr);
        final notifIndex = _mockNotifications.indexWhere((n) => n['id'] == id);
        if (notifIndex != -1) {
          _mockNotifications[notifIndex]['read_at'] = DateTime.now().toIso8601String();
          _mockNotifications[notifIndex]['read'] = true;
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {'message': 'Notification marked as read'},
          ));
        }
      }

      // Default 404 for unhandled mocks
      return handler.reject(DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 404,
          data: {'message': 'Mock Route Not Found'},
        ),
      ));
    } catch (e) {
      return handler.reject(DioException(
        requestOptions: options,
        error: e.toString(),
      ));
    }
  }

  // Sample Customer Names
  static const List<String> _customerNames = [
    'Alice Jenkins',
    'Bob Carter',
    'Charles Miller',
    'Diana Prince',
    'Ethan Hunt',
    'Fiona Gallagher',
    'George Cooper',
    'Hannah Abbott',
    'Ian Malcolm',
    'Julia Roberts',
    'Kevin Hart',
    'Laura Croft',
    'Marcus Aurelius',
    'Nancy Wheeler',
    'Oscar Wilde',
  ];

  // Mock Contracts
  static final List<Map<String, dynamic>> _mockContracts = [
    {
      'id': 1001,
      'code': 'MG-STD-12M',
      'name': 'Standard 12 Months Protection',
      'duration_months': 12,
      'price': 49.99,
      'status': 'Active',
      'description': 'Covers software locks, screen crack replacement insurance, and remote lock controls.',
      'terms': 'Requires installation of MobiGuard client app on devices. Device must not be rooted or jailbroken.',
    },
    {
      'id': 1002,
      'code': 'MG-PREM-24M',
      'name': 'Premium 24 Months Complete Care',
      'duration_months': 24,
      'price': 89.99,
      'status': 'Active',
      'description': 'Advanced security locks, hardware damage waiver, theft replacement support, and priority agent support.',
      'terms': 'IMEI registration matching purchase receipt. Limit of two hardware claims over the duration.',
    },
    {
      'id': 1003,
      'code': 'MG-LITE-6M',
      'name': 'Lite Guard 6 Months Protection',
      'duration_months': 6,
      'price': 29.99,
      'status': 'Active',
      'description': 'Basic remote lock controls, SIM switch detection, and basic factory reset protection.',
      'terms': 'Applicable to entry-level devices. No theft replacement coverage included.',
    },
  ];

  // Mock Transactions
  static final List<Map<String, dynamic>> _mockTransactions = [
    {
      'id': 'TXN-9081',
      'type': 'Credit',
      'source': 'Admin Deposit (Top-up)',
      'amount': 500.00,
      'status': 'Completed',
      'date': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
    },
    {
      'id': 'TXN-9040',
      'type': 'Debit',
      'source': 'Enrollment: ENR-88390',
      'amount': 49.99,
      'status': 'Completed',
      'date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    },
    {
      'id': 'TXN-8988',
      'type': 'Debit',
      'source': 'Enrollment: ENR-88301',
      'amount': 89.99,
      'status': 'Completed',
      'date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
    },
    {
      'id': 'TXN-8742',
      'type': 'Credit',
      'source': 'Bank Transfer (Top-up)',
      'amount': 1000.00,
      'status': 'Completed',
      'date': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
    },
    {
      'id': 'TXN-8701',
      'type': 'Debit',
      'source': 'Enrollment: ENR-87002',
      'amount': 49.99,
      'status': 'Completed',
      'date': DateTime.now().subtract(const Duration(days: 6)).toIso8601String(),
    },
    {
      'id': 'TXN-TOP-PEND',
      'type': 'Credit',
      'source': 'Top-up Request (Pending Approval)',
      'amount': 250.00,
      'status': 'Pending',
      'date': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
    }
  ];

  // Mock Notifications
  static final List<Map<String, dynamic>> _mockNotifications = [
    {
      'id': 1,
      'title': 'Enrollment Approved',
      'body': 'Enrollment ENR-88390 has been verified and device is fully protected.',
      'read': false,
      'read_at': null,
      'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
    },
    {
      'id': 2,
      'title': 'Top-up Deposit Added',
      'body': 'Your wallet has been credited with \$500.00. Reference: TXN-9081.',
      'read': false,
      'read_at': null,
      'created_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
    },
    {
      'id': 3,
      'title': 'System Maintenance',
      'body': 'MobiGuard server will undergo maintenance tonight at 02:00 AM UTC. Services may face slight delays.',
      'read': true,
      'read_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    },
  ];
}
