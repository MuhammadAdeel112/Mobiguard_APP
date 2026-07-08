import 'package:intl/intl.dart';

class Helpers {
  // Format dates consistently across the app
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
  }

  static String formatDate(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  // Format currency consistently
  static String formatCurrency(double amount) {
    return NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2).format(amount);
  }

  // Validate Email formats
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim());
  }

  // Validate 15-digit IMEI slot codes
  static bool isValidImei(String imei) {
    if (imei.trim().length != 15) return false;
    return double.tryParse(imei.trim()) != null;
  }

  static String groupDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    if (day == today) return 'TODAY';
    if (day == today.subtract(const Duration(days: 1))) return 'YESTERDAY';
    return DateFormat('MMMM d, yyyy').format(date);
  }
}
