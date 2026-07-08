class StorageKeys {
  static const String token = 'auth_token';
  static const String user = 'auth_user';
  static const String environment = 'app_environment';
}

class AppPermissions {
  static const customersView = 'customers.view';
  static const customersCreate = 'customers.create';
  static const contractsView = 'contracts.view';
  static const enrollmentsCreate = 'enrollments.create';
  static const walletView = 'wallet.view';
  static const walletTopupCreate = 'wallet_topups.create';
}

class ApiPaths {
  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/me';

  // Customers
  static const String customers = '/customers';

  // Contracts
  static const String contracts = '/contracts';

  // Enrollments
  static const String enrollmentRequests = '/enrollment-requests';

  // Devices
  static const String devices = '/devices';

  // Operational Requests (replacement, unenroll, wallet topup approval)
  static const String operationalRequests = '/operational-requests';

  // Wallet
  static const String wallet = '/wallet';
  static const String walletTopup = '/wallet/topup-requests';

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static const String notificationsReadAll = '/notifications/read-all';
}
