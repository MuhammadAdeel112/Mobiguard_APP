import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../enrollment_providers.dart';
import '../../customers/customers_providers.dart';
import '../../contracts/contracts_providers.dart';
import '../../../core/theme/app_theme.dart';

class EnrollmentScreen extends ConsumerStatefulWidget {
  const EnrollmentScreen({super.key});

  @override
  ConsumerState<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends ConsumerState<EnrollmentScreen> {
  final _formKey = GlobalKey<FormState>();
  
  CustomerModel? _selectedCustomer;
  ContractModel? _selectedContract;
  
  String? _selectedBrand;
  final _modelController = TextEditingController();
  final _imei1Controller = TextEditingController();
  final _imei2Controller = TextEditingController();
  
  bool _isLoading = false;

  final List<String> _brands = [
    'Apple',
    'Samsung',
    'Google',
    'Xiaomi',
    'OnePlus',
    'Motorola',
    'Oppo',
    'Huawei',
    'Nokia',
  ];

  @override
  void dispose() {
    _modelController.dispose();
    _imei1Controller.dispose();
    _imei2Controller.dispose();
    super.dispose();
  }

  Future<void> _submitEnrollment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      _showErrorSnackBar('Please select a customer');
      return;
    }
    if (_selectedContract == null) {
      _showErrorSnackBar('Please select a contract');
      return;
    }

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
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customerListProvider);
    final contractState = ref.watch(contractsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Enrollment'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step header
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Device Registration Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer dropdown
                        const Text('Customer Selection', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<CustomerModel>(
                          initialValue: _selectedCustomer,
                          hint: const Text('Select active customer'),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.person),
                          ),
                          items: customerState.customers.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Text(c.name, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedCustomer = val);
                          },
                          validator: (val) => val == null ? 'Please select a customer' : null,
                        ),
                        const SizedBox(height: 16),

                        // Contract dropdown
                        const Text('Service Contract Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<ContractModel>(
                          initialValue: _selectedContract,
                          hint: const Text('Select warranty contract'),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.description),
                          ),
                          isExpanded: true,
                          items: contractState.contracts.map((c) {
                            final amountStr = c.installmentAmount.toStringAsFixed(0);
                            return DropdownMenuItem(
                              value: c,
                              child: Text(
                                '${c.contractNo}  •  PKR $amountStr',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedContract = val);
                          },
                          validator: (val) => val == null ? 'Please select a contract' : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Device Info Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    key: const ValueKey('enrollment_device_card'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Hardware Specifications', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 12),
                        
                        // Device Brand
                        DropdownButtonFormField<String>(
                          initialValue: _selectedBrand,
                          hint: const Text('Select Brand'),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.phone_android),
                          ),
                          items: _brands.map((b) {
                            return DropdownMenuItem(
                              value: b,
                              child: Text(b),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedBrand = val);
                          },
                          validator: (val) => val == null ? 'Please select a brand' : null,
                        ),
                        const SizedBox(height: 16),

                        // Device Model
                        TextFormField(
                          controller: _modelController,
                          decoration: const InputDecoration(
                            labelText: 'Device Model',
                            prefixIcon: Icon(Icons.settings_suggest_outlined),
                            hintText: 'e.g. Galaxy S24 Ultra / iPhone 15',
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter the device model';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // IMEI 1
                        TextFormField(
                          controller: _imei1Controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'IMEI 1',
                            prefixIcon: Icon(Icons.fingerprint),
                            hintText: '15-digit unique serial number',
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter IMEI 1';
                            }
                            if (val.trim().length != 15 || double.tryParse(val.trim()) == null) {
                              return 'IMEI must be exactly 15 numeric digits';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // IMEI 2
                        TextFormField(
                          controller: _imei2Controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'IMEI 2 (Optional)',
                            prefixIcon: Icon(Icons.fingerprint),
                            hintText: 'Secondary slot IMEI',
                          ),
                          validator: (val) {
                            if (val != null && val.trim().isNotEmpty) {
                              if (val.trim().length != 15 || double.tryParse(val.trim()) == null) {
                                return 'IMEI 2 must be exactly 15 numeric digits';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitEnrollment,
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
                      : const Text('Initiate Enrollment'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
