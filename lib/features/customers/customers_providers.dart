import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/global_providers.dart';
import '../../core/constants/constants.dart';
import '../../core/error/exceptions.dart';

class CustomerModel {
  final int id;
  final int companyId;
  final int branchId;
  final String name;
  final String cnic;
  final String phone;
  final String address;
  final String status;

  CustomerModel({
    required this.id,
    required this.companyId,
    required this.branchId,
    required this.name,
    required this.cnic,
    required this.phone,
    required this.address,
    required this.status,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as int,
      companyId: json['company_id'] as int? ?? 0,
      branchId: json['branch_id'] as int? ?? 0,
      name: json['name'] as String,
      cnic: json['cnic'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'branch_id': branchId,
        'name': name,
        'cnic': cnic,
        'phone': phone,
        'address': address,
        'status': status,
      };
}

class CustomerListState {
  final List<CustomerModel> customers;
  final int total;
  final int page;
  final bool hasReachedMax;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  CustomerListState({
    required this.customers,
    required this.total,
    required this.page,
    required this.hasReachedMax,
    required this.searchQuery,
    required this.isLoading,
    this.error,
  });

  factory CustomerListState.initial() => CustomerListState(
        customers: [],
        total: 0,
        page: 1,
        hasReachedMax: false,
        searchQuery: '',
        isLoading: false,
      );

  CustomerListState copyWith({
    List<CustomerModel>? customers,
    int? total,
    int? page,
    bool? hasReachedMax,
    String? searchQuery,
    bool? isLoading,
    String? error,
  }) {
    return CustomerListState(
      customers: customers ?? this.customers,
      total: total ?? this.total,
      page: page ?? this.page,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchQuery: searchQuery ?? this.searchQuery,
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

class CustomerListNotifier extends StateNotifier<CustomerListState> {
  final Ref _ref;

  CustomerListNotifier(this._ref) : super(CustomerListState.initial()) {
    fetchCustomers();
  }

  Future<void> fetchCustomers({bool isRefresh = false}) async {
    if (state.isLoading) return;
    if (!isRefresh && state.hasReachedMax) return;

    final targetPage = isRefresh ? 1 : state.page;
    
    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiClient = _ref.read(apiClientProvider);
      
      // We pass the parameters as query parameters directly
      final response = await apiClient.get(
        ApiPaths.customers,
        queryParameters: {
          'page': targetPage,
          'per_page': 25,
          if (state.searchQuery.isNotEmpty) 'q': state.searchQuery,
        },
      );

      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'] as List;
      final meta = responseData['meta'] as Map<String, dynamic>?;
      final currentLastPage = meta != null ? (meta['last_page'] as int? ?? 1) : 1;

      final fetchedCustomers = data.map((json) => CustomerModel.fromJson(json)).toList();
      final updatedCustomers =
          isRefresh ? fetchedCustomers : [...state.customers, ...fetchedCustomers];

      state = state.copyWith(
        isLoading: false,
        customers: updatedCustomers,
        total: _extractListTotal(responseData, updatedCustomers.length),
        page: targetPage + 1,
        hasReachedMax: targetPage >= currentLastPage,
      );
    } on Failure catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'An unexpected error occurred: ${e.toString()}');
    }
  }

  void searchCustomers(String query) {
    if (state.searchQuery == query) return;
    state = state.copyWith(
      searchQuery: query,
      customers: [],
      page: 1,
      hasReachedMax: false,
    );
    fetchCustomers(isRefresh: true);
  }

  Future<CustomerModel> createCustomer({
    required String name,
    required String phone,
    String cnic = '',
    String address = '',
  }) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      
      // Only send fields that have values (Backend allows cnic and address to be null/empty)
      final Map<String, dynamic> requestData = {
        'name': name,
        'phone': phone,
      };
      if (cnic.isNotEmpty) requestData['cnic'] = cnic;
      if (address.isNotEmpty) requestData['address'] = address;

      final response = await apiClient.post(
        ApiPaths.customers,
        data: requestData,
      );

      final customerData = response.data['data'] ?? response.data;
      final customer = CustomerModel.fromJson(customerData);
      
      // Prepend to current list
      state = state.copyWith(
        customers: [customer, ...state.customers],
        total: state.total + 1,
      );
      return customer;
    } on Failure catch (e) {
      throw e;
    } catch (e) {
      throw Failure(e.toString());
    }
  }
}

final customerListProvider = StateNotifierProvider<CustomerListNotifier, CustomerListState>((ref) {
  return CustomerListNotifier(ref);
});
