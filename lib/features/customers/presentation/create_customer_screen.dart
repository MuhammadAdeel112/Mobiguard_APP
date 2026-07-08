import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../customers_providers.dart';
import '../../../core/theme/app_theme.dart';

class CreateCustomerScreen extends ConsumerStatefulWidget {
  const CreateCustomerScreen({super.key});

  @override
  ConsumerState<CreateCustomerScreen> createState() => _CreateCustomerScreenState();
}

class _CreateCustomerScreenState extends ConsumerState<CreateCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cnicController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final customer = await ref.read(customerListProvider.notifier).createCustomer(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            cnic: _cnicController.text.trim(),
            address: _addressController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Customer "${customer.name}" created successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Customer'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Full Name
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline),
                            hintText: 'John Doe',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a name';
                            }
                            if (value.trim().length < 3) {
                              return 'Name must be at least 3 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Phone Number
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone_android),
                            hintText: '03001234567',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // CNIC
                        TextFormField(
                          controller: _cnicController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'CNIC Number',
                            prefixIcon: Icon(Icons.badge_outlined),
                            hintText: '3520212345671',
                          ),
                          validator: (value) {
                            if (value != null && value.trim().isNotEmpty && value.trim().length != 13) {
                              return 'CNIC must be 13 digits without dashes';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Address
                        TextFormField(
                          controller: _addressController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Physical Address',
                            prefixIcon: Icon(Icons.location_on_outlined),
                            hintText: '123 Main St, Metro City',
                          ),
                          validator: (value) {
                            if (value != null && value.trim().isNotEmpty && value.trim().length < 5) {
                              return 'Address is too short';
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
                  onPressed: _isLoading ? null : _submitForm,
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
                      : const Text('Save Customer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
