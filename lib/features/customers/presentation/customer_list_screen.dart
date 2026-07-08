import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/auth_providers.dart';
import '../../../core/constants/constants.dart';
import '../customers_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_ui.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(customerListProvider.notifier).fetchCustomers();
    }
  }

  void _onSearchChanged(String value) {
    ref.read(customerListProvider.notifier).searchCustomers(value.trim());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerListProvider);
    final user = ref.watch(authProvider).user;
    final canCreate = user?.hasPermission(AppPermissions.customersCreate) ?? false;

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      appBar: ReferenceAppBar.preferred(context, title: 'Customer Directory'),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/customers/create'),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            )
          : null,
      body: ReferenceBodyClip(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search name, phone, or CNIC...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                ),
              ),
            ),
            if (state.error != null)
              ErrorBanner(
                message: state.error!,
                onRetry: () => ref.read(customerListProvider.notifier).fetchCustomers(isRefresh: true),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref.read(customerListProvider.notifier).fetchCustomers(isRefresh: true);
                },
                child: state.isLoading && state.customers.isEmpty
                    ? const ListSkeleton()
                    : state.customers.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              EmptyState(
                                icon: Icons.people_outline,
                                title: 'No customers found',
                                subtitle: canCreate
                                    ? 'Add your first customer to start device enrollments.'
                                    : 'Customers will appear here once added.',
                                actionLabel: canCreate ? 'Add Customer' : null,
                                onAction: canCreate ? () => context.push('/customers/create') : null,
                              ),
                            ],
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                            itemCount: state.customers.length + (state.isLoading ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == state.customers.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(AppSpacing.md),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }

                              final customer = state.customers[index];
                              final isActive = customer.status.toLowerCase() == 'active';

                              return Card(
                                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    child: Text(
                                      customer.name.substring(0, 1).toUpperCase(),
                                      style: const TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          customer.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                      ),
                                      StatusChip(
                                        label: customer.status.toUpperCase(),
                                        color: isActive ? Colors.green : Colors.orange,
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        Icon(Icons.phone_android, size: 13, color: Colors.grey.shade500),
                                        const SizedBox(width: 4),
                                        Text(customer.phone, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                      ],
                                    ),
                                  ),
                                  trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
                                  onTap: () => context.push('/customers/${customer.id}', extra: customer),
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
