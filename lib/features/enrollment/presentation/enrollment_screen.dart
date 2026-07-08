import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/auth_providers.dart';
import '../../../core/constants/constants.dart';
import '../../../core/helpers.dart';
import '../enrollment_providers.dart';
import '../../customers/customers_providers.dart';
import '../../contracts/contracts_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_ui.dart';
import '../../../shared/widgets/app_scaffold.dart';

class EnrollmentScreen extends ConsumerStatefulWidget {
  const EnrollmentScreen({super.key});

  @override
  ConsumerState<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends ConsumerState<EnrollmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;

  CustomerModel? _selectedCustomer;
  ContractModel? _selectedContract;

  String? _selectedBrand;
  final _modelController = TextEditingController();
  final _imei1Controller = TextEditingController();
  final _imei2Controller = TextEditingController();

  bool _isLoading = false;
  bool _routeParamsApplied = false;

  final List<String> _brands = [
    'Apple', 'Samsung', 'Google', 'Xiaomi', 'OnePlus',
    'Motorola', 'Oppo', 'Huawei', 'Nokia',
  ];

  static const _stepLabels = ['Customer', 'Contract', 'Device'];

  @override
  void dispose() {
    _pageController.dispose();
    _modelController.dispose();
    _imei1Controller.dispose();
    _imei2Controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeParamsApplied) return;
    _routeParamsApplied = true;

    final params = GoRouterState.of(context).uri.queryParameters;
    final customerId = int.tryParse(params['customerId'] ?? '');
    final contractId = int.tryParse(params['contractId'] ?? '');

    final customers = ref.read(customerListProvider).customers;
    final contracts = ref.read(contractsProvider).contracts;

    CustomerModel? customer;
    ContractModel? contract;

    if (customerId != null) {
      for (final c in customers) {
        if (c.id == customerId) {
          customer = c;
          break;
        }
      }
    }

    if (contractId != null) {
      for (final c in contracts) {
        if (c.id == contractId) {
          contract = c;
          break;
        }
      }
    }

    if (customer != null || contract != null) {
      setState(() {
        _selectedCustomer = customer ?? _selectedCustomer;
        _selectedContract = contract ?? _selectedContract;
        if (customer != null && contract != null) {
          _currentStep = 2;
        } else if (customer != null || contract != null) {
          _currentStep = 1;
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_currentStep);
        }
      });
    }
  }

  bool _validateStep0() {
    if (_selectedCustomer == null) {
      _showErrorSnackBar('Please select a customer');
      return false;
    }
    return true;
  }

  bool _validateStep1() {
    if (_selectedContract == null) {
      _showErrorSnackBar('Please select a contract');
      return false;
    }
    return true;
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextStep() {
    if (_currentStep == 0 && !_validateStep0()) return;
    if (_currentStep == 1 && !_validateStep1()) return;
    if (_currentStep < 2) _goToStep(_currentStep + 1);
  }

  void _prevStep() {
    if (_currentStep > 0) _goToStep(_currentStep - 1);
  }

  Future<void> _submitEnrollment() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateStep0() || !_validateStep1()) return;

    setState(() => _isLoading = true);

    try {
      final enrollment = await ref.read(enrollmentProvider.notifier).createEnrollment(
            customerId: _selectedCustomer!.id,
            contractId: _selectedContract!.id,
            brand: _selectedBrand!,
            model: _modelController.text.trim(),
            imei1: _imei1Controller.text.trim(),
            imei2: _imei2Controller.text.trim(),
          );

      if (mounted) {
        final encodedPayload = Uri.encodeComponent(enrollment.qrPayloadString);
        context.go('/enrollment/verify/${enrollment.enrollmentRequestId}?qr_payload=$encodedPayload');
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildEmptyBanner({
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.amber.shade800),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(fontSize: 12, color: Colors.amber.shade900))),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customerListProvider);
    final contractState = ref.watch(contractsProvider);
    final user = ref.watch(authProvider).user;
    final canEnroll = user?.hasPermission(AppPermissions.enrollmentsCreate) ?? false;
    final canCreateCustomer = user?.hasPermission(AppPermissions.customersCreate) ?? false;
    final canViewContracts = user?.hasPermission(AppPermissions.contractsView) ?? false;

    final customersEmpty = customerState.customers.isEmpty && !customerState.isLoading;
    final contractsEmpty = contractState.contracts.isEmpty && !contractState.isLoading;
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      appBar: ReferenceAppBar.preferred(
        context,
        title: 'Device Enrollment',
        actions: [
          if (canViewContracts)
            TextButton(
              onPressed: () => context.push('/contracts'),
              child: const Text('Contracts', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: ReferenceBodyClip(
        child: !canEnroll
            ? const EmptyState(
                icon: Icons.lock_outline,
                title: 'Access restricted',
                subtitle: 'You do not have permission to create enrollments.',
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: StepIndicator(currentStep: _currentStep, labels: _stepLabels),
                  ),
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        onPageChanged: (i) => setState(() => _currentStep = i),
                        children: [
                          _buildStep0(customerState, customersEmpty, canCreateCustomer),
                          _buildStep1(contractState, contractsEmpty, canViewContracts),
                          _buildStep2(),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomBar(customersEmpty, contractsEmpty),
                ],
              ),
      ),
    );
  }

  Widget _buildStep0(CustomerListState customerState, bool customersEmpty, bool canCreateCustomer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Select Customer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.sm),
          Text('Choose the customer for this device enrollment.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: AppSpacing.md),
          if (customersEmpty)
            _buildEmptyBanner(
              message: 'No customers available.',
              actionLabel: 'Add Customer',
              onAction: canCreateCustomer
                  ? () => context.push('/customers/create')
                  : () => _showErrorSnackBar('No permission to add customers'),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: DropdownButtonFormField<CustomerModel>(
                initialValue: _selectedCustomer,
                hint: const Text('Select active customer'),
                decoration: const InputDecoration(prefixIcon: Icon(Icons.person)),
                isExpanded: true,
                items: customerState.customers.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c.name, overflow: TextOverflow.ellipsis));
                }).toList(),
                onChanged: customersEmpty ? null : (val) => setState(() => _selectedCustomer = val),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1(ContractListState contractState, bool contractsEmpty, bool canViewContracts) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Select Contract', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.sm),
          Text('Pick the protection plan for this enrollment.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: AppSpacing.md),
          if (contractsEmpty)
            _buildEmptyBanner(
              message: 'No contracts available.',
              actionLabel: 'View Contracts',
              onAction: canViewContracts
                  ? () => context.push('/contracts')
                  : () => _showErrorSnackBar('No permission to view contracts'),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: DropdownButtonFormField<ContractModel>(
                initialValue: _selectedContract,
                hint: const Text('Select warranty contract'),
                decoration: const InputDecoration(prefixIcon: Icon(Icons.description)),
                isExpanded: true,
                items: contractState.contracts.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Text(
                      '${c.contractNo}  •  ${Helpers.formatCurrency(c.installmentAmount)}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: contractsEmpty ? null : (val) => setState(() => _selectedContract = val),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Device Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.sm),
          Text('Enter the device brand, model, and IMEI numbers.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedBrand,
                    hint: const Text('Select Brand'),
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.phone_android)),
                    items: _brands.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                    onChanged: (val) => setState(() => _selectedBrand = val),
                    validator: (val) => val == null ? 'Please select a brand' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _modelController,
                    decoration: const InputDecoration(
                      labelText: 'Device Model',
                      prefixIcon: Icon(Icons.settings_suggest_outlined),
                      hintText: 'e.g. Galaxy S24 Ultra',
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter the device model' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _imei1Controller,
                    keyboardType: TextInputType.number,
                    maxLength: 15,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'IMEI 1',
                      prefixIcon: const Icon(Icons.fingerprint),
                      counterText: '${_imei1Controller.text.length}/15',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Please enter IMEI 1';
                      if (!Helpers.isValidImei(val.trim())) return 'IMEI must be exactly 15 digits';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _imei2Controller,
                    keyboardType: TextInputType.number,
                    maxLength: 15,
                    decoration: InputDecoration(
                      labelText: 'IMEI 2 (Optional)',
                      prefixIcon: const Icon(Icons.fingerprint),
                      counterText: _imei2Controller.text.isEmpty ? null : '${_imei2Controller.text.length}/15',
                    ),
                    validator: (val) {
                      if (val != null && val.trim().isNotEmpty && !Helpers.isValidImei(val.trim())) {
                        return 'IMEI 2 must be exactly 15 digits';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool customersEmpty, bool contractsEmpty) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md + AppScaffold.fabOverlapClearance,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(onPressed: _prevStep, child: const Text('Back')),
            ),
          if (_currentStep > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading || customersEmpty || contractsEmpty
                  ? null
                  : (_currentStep < 2 ? _nextStep : _submitEnrollment),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(_currentStep < 2 ? 'Continue' : 'Initiate Enrollment'),
            ),
          ),
        ],
      ),
    );
  }
}
