import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../contracts_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_ui.dart';

class ContractListScreen extends ConsumerStatefulWidget {
  const ContractListScreen({super.key});

  @override
  ConsumerState<ContractListScreen> createState() => _ContractListScreenState();
}

class _ContractListScreenState extends ConsumerState<ContractListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(contractsProvider.notifier).fetchContracts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contractsProvider);
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    final dateFormatter = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Contracts'),
      ),
      body: Column(
        children: [
          // Error banner
          if (state.error != null)
            ErrorBanner(
              message: state.error!,
              onRetry: () => ref.read(contractsProvider.notifier).fetchContracts(isRefresh: true),
            ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(contractsProvider.notifier).fetchContracts(isRefresh: true);
              },
              child: state.isLoading && state.contracts.isEmpty
                  ? const ListSkeleton()
                  : state.contracts.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            EmptyState(
                              icon: Icons.description_outlined,
                              title: 'No contracts available',
                              subtitle: 'Active contracts assigned to your branch will appear here.',
                            ),
                          ],
                        )
                      : ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      itemCount: state.contracts.length + (state.isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.contracts.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final contract = state.contracts[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => context.push('/contracts/${contract.id}'),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          contract.contractNo,
                                          style: const TextStyle(
                                            color: AppTheme.primaryColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      StatusChip.fromStatus(contract.status),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.person, color: Colors.grey, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          contract.customer.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.storefront, color: Colors.grey, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        contract.branch.name,
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'INSTALLMENT',
                                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            formatter.format(contract.installmentAmount),
                                            style: TextStyle(
                                              color: theme.colorScheme.primary,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'STARTED',
                                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            dateFormatter.format(contract.startDate),
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
