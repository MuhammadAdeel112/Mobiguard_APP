import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/global_providers.dart';
import '../../core/constants/constants.dart';

class TransactionModel {
  final String id;
  final String type; // 'Credit' or 'Debit'
  final String source;
  final double amount;
  final String status; // 'Completed' or 'Pending'
  final DateTime date;

  TransactionModel({
    required this.id,
    required this.type,
    required this.source,
    required this.amount,
    required this.status,
    required this.date,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'Credit',
      source: (json['source'] ?? json['description'] ?? json['note'] ?? 'Transaction').toString(),
      amount: double.parse((json['amount'] ?? 0).toString()),
      status: json['status']?.toString() ?? 'Completed',
      date: DateTime.tryParse(json['date']?.toString() ?? json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class WalletState {
  final double balance;
  final String currency;
  final bool walletEnabled;
  final String walletStatus;
  final List<TransactionModel> transactions;

  WalletState({
    required this.balance,
    required this.currency,
    required this.walletEnabled,
    required this.walletStatus,
    required this.transactions,
  });

  factory WalletState.initial() => WalletState(
        balance: 0.0,
        currency: 'PKR',
        walletEnabled: false,
        walletStatus: 'pending',
        transactions: [],
      );

  WalletState copyWith({
    double? balance,
    String? currency,
    bool? walletEnabled,
    String? walletStatus,
    List<TransactionModel>? transactions,
  }) {
    return WalletState(
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      walletEnabled: walletEnabled ?? this.walletEnabled,
      walletStatus: walletStatus ?? this.walletStatus,
      transactions: transactions ?? this.transactions,
    );
  }
}

class WalletNotifier extends StateNotifier<AsyncValue<WalletState>> {
  final Ref _ref;

  WalletNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetchWallet();
  }

  Future<void> fetchWallet() async {
    state = const AsyncValue.loading();
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.get(ApiPaths.wallet);
      final data = response.data;
      
      final txs = (data['transactions'] as List)
          .map((json) => TransactionModel.fromJson(json))
          .toList();
      
      state = AsyncValue.data(WalletState(
        balance: double.parse(data['balance'].toString()),
        currency: 'PKR', // Setting PKR as default for Pakistan
        walletEnabled: data['wallet_enabled'] as bool? ?? false,
        walletStatus: data['wallet_status'] as String? ?? 'inactive',
        transactions: txs,
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> requestTopup(double amount, String imagePath) async {
    final apiClient = _ref.read(apiClientProvider);
    final filename = imagePath.split('/').last;

    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Screenshot file does not exist');
      }

      final formData = FormData.fromMap({
        'amount': amount,
        'screenshot': await MultipartFile.fromFile(
          imagePath,
          filename: filename,
        ),
      });

      final response = await apiClient.post(
        ApiPaths.walletTopup,
        data: formData,
      );

      final responseData = response.data;
      if (responseData['status'] == 'success') {
        final rawTx = responseData['request'];
        final newTx = TransactionModel(
          id: rawTx['id']?.toString() ?? 'TRX-TOP-${DateTime.now().millisecond}',
          type: 'Credit',
          source: 'Top-up Request (Pending Approval)',
          amount: amount,
          status: 'Pending',
          date: DateTime.parse(rawTx['created_at'] ?? DateTime.now().toIso8601String()),
        );

        state.whenData((current) {
          state = AsyncValue.data(current.copyWith(
            transactions: [newTx, ...current.transactions],
          ));
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  // Deduct balance locally when enrollment is successful
  void deductBalance(double amount, String source) {
    state.whenData((current) {
      final newTx = TransactionModel(
        id: 'TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        type: 'Debit',
        source: source,
        amount: amount,
        status: 'Completed',
        date: DateTime.now(),
      );

      state = AsyncValue.data(current.copyWith(
        balance: current.balance - amount,
        transactions: [newTx, ...current.transactions],
      ));
    });
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, AsyncValue<WalletState>>((ref) {
  return WalletNotifier(ref);
});
