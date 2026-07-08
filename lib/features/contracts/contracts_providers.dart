import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/global_providers.dart';
import '../../core/constants/constants.dart';
import '../../core/error/exceptions.dart';

class ContractCustomer {
  final int id;
  final String name;
  final String? phone;

  ContractCustomer({required this.id, required this.name, this.phone});

  factory ContractCustomer.fromJson(Map<String, dynamic> json) {
    return ContractCustomer(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String?,
    );
  }
}

class ContractBranch {
  final int id;
  final String name;
  final String? branchCode;

  ContractBranch({required this.id, required this.name, this.branchCode});

  factory ContractBranch.fromJson(Map<String, dynamic> json) {
    return ContractBranch(
      id: json['id'] as int,
      name: json['name'] as String,
      branchCode: json['branch_code'] as String?,
    );
  }
}

class InstallmentModel {
  final int id;
  final DateTime dueDate;
  final double amount;
  final String status;

  InstallmentModel({
    required this.id,
    required this.dueDate,
    required this.amount,
    required this.status,
  });

  factory InstallmentModel.fromJson(Map<String, dynamic> json) {
    return InstallmentModel(
      id: json['id'] as int,
      dueDate: DateTime.parse(json['due_date'] as String),
      amount: double.parse(json['amount'].toString()),
      status: json['status'] as String,
    );
  }
}

class ContractDetailModel {
  final int id;
  final String contractNo;
  final String status;
  final ContractCustomer customer;
  final ContractBranch branch;
  final double totalAmount;
  final double installmentAmount;
  final int durationMonths;
  final DateTime startDate;
  final List<InstallmentModel> installments;
  final Map<String, dynamic>? device;

  ContractDetailModel({
    required this.id,
    required this.contractNo,
    required this.status,
    required this.customer,
    required this.branch,
    required this.totalAmount,
    required this.installmentAmount,
    required this.durationMonths,
    required this.startDate,
    required this.installments,
    this.device,
  });

  factory ContractDetailModel.fromJson(Map<String, dynamic> json) {
    return ContractDetailModel(
      id: json['id'] as int,
      contractNo: json['contract_no'] as String,
      status: json['status'] as String,
      customer: ContractCustomer.fromJson(json['customer']),
      branch: ContractBranch.fromJson(json['branch']),
      totalAmount: double.parse(json['total_amount'].toString()),
      installmentAmount: double.parse(json['installment_amount'].toString()),
      durationMonths: json['duration_months'] as int,
      startDate: DateTime.parse(json['start_date'] as String),
      installments: (json['installments'] as List)
          .map((i) => InstallmentModel.fromJson(i))
          .toList(),
      device: json['device'] as Map<String, dynamic>?,
    );
  }
}

class ContractModel {
  final int id;
  final String contractNo;
  final String status;
  final ContractCustomer customer;
  final ContractBranch branch;
  final double installmentAmount;
  final int durationMonths;
  final DateTime startDate;

  ContractModel({
    required this.id,
    required this.contractNo,
    required this.status,
    required this.customer,
    required this.branch,
    required this.installmentAmount,
    required this.durationMonths,
    required this.startDate,
  });

  factory ContractModel.fromJson(Map<String, dynamic> json) {
    return ContractModel(
      id: json['id'] as int,
      contractNo: json['contract_no'] as String,
      status: json['status'] as String,
      customer: ContractCustomer.fromJson(json['customer']),
      branch: ContractBranch.fromJson(json['branch']),
      installmentAmount: double.parse(json['installment_amount'].toString()),
      durationMonths: json['duration_months'] as int,
      startDate: DateTime.parse(json['start_date'] as String),
    );
  }
}

class ContractListState {
  final List<ContractModel> contracts;
  final int total;
  final int page;
  final bool hasReachedMax;
  final bool isLoading;
  final String? error;

  ContractListState({
    required this.contracts,
    required this.total,
    required this.page,
    required this.hasReachedMax,
    required this.isLoading,
    this.error,
  });

  factory ContractListState.initial() => ContractListState(
        contracts: [],
        total: 0,
        page: 1,
        hasReachedMax: false,
        isLoading: false,
      );

  ContractListState copyWith({
    List<ContractModel>? contracts,
    int? total,
    int? page,
    bool? hasReachedMax,
    bool? isLoading,
    String? error,
  }) {
    return ContractListState(
      contracts: contracts ?? this.contracts,
      total: total ?? this.total,
      page: page ?? this.page,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

int _extractListTotal(Map<String, dynamic> responseData, int fallback) {
  final meta = responseData['meta'];
  if (meta is Map && meta['total'] != null) {
    return meta['total'] as int;
  }
  if (responseData['total'] != null) {
    return responseData['total'] as int;
  }
  return fallback;
}

class ContractsNotifier extends StateNotifier<ContractListState> {
  final Ref _ref;

  ContractsNotifier(this._ref) : super(ContractListState.initial()) {
    fetchContracts();
  }

  Future<void> fetchContracts({bool isRefresh = false}) async {
    if (state.isLoading) return;
    if (!isRefresh && state.hasReachedMax) return;

    final targetPage = isRefresh ? 1 : state.page;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiClient = _ref.read(apiClientProvider);
      
      final response = await apiClient.get(
        ApiPaths.contracts,
        queryParameters: {
          'page': targetPage,
          'per_page': 25,
        },
      );

      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'] as List;
      final meta = responseData['meta'] as Map<String, dynamic>?;
      final currentLastPage = meta != null ? (meta['last_page'] as int? ?? 1) : 1;

      final fetchedContracts = data.map((json) => ContractModel.fromJson(json)).toList();
      final updatedContracts =
          isRefresh ? fetchedContracts : [...state.contracts, ...fetchedContracts];

      state = state.copyWith(
        isLoading: false,
        contracts: updatedContracts,
        total: _extractListTotal(responseData, updatedContracts.length),
        page: targetPage + 1,
        hasReachedMax: targetPage >= currentLastPage,
      );
    } on Failure catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load contracts: $e');
    }
  }
}

final contractsProvider = StateNotifierProvider<ContractsNotifier, ContractListState>((ref) {
  return ContractsNotifier(ref);
});

// Full detail provider — always fetches from API to get installments, device etc.
final contractDetailProvider = FutureProvider.family<ContractDetailModel, int>((ref, id) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get('${ApiPaths.contracts}/$id');
  return ContractDetailModel.fromJson(response.data);
});
