import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_ui.dart';
import '../auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  static const _iconBoxColor = Color(0xFFEFF6FF);
  static const _iconColor = Color(0xFF2563EB);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 12, right: 4),
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _iconBoxColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(prefixIcon, color: _iconColor, size: 20),
        ),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 62, minHeight: 48),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppTheme.lightBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppTheme.lightBg,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.primaryColor,
        resizeToAvoidBottomInset: false,
        appBar: ReferenceAppBar.preferred(
          context,
          title: 'MobiGuard Sales',
          subtitle: 'Agent Portal',
        ),
        body: ReferenceBodyClip(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(4, 16, 4, 20 + bottomInset),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 36),
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _iconBoxColor,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.login_rounded,
                                    color: _iconColor,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome back',
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Sign in to continue to your account',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        width: 40,
                                        height: 3,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            _fieldLabel('Email address'),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              style: const TextStyle(fontSize: 16),
                              decoration: _inputDecoration(
                                hint: 'you@company.com',
                                prefixIcon: Icons.email_outlined,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _fieldLabel('Password'),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              onFieldSubmitted: (_) {
                                if (!_isLoading) _handleLogin();
                              },
                              style: const TextStyle(fontSize: 16),
                              decoration: _inputDecoration(
                                hint: 'Enter your password',
                                prefixIcon: Icons.lock_outline,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.grey.shade500,
                                    size: 22,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      AppTheme.primaryColor.withValues(alpha: 0.6),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Sign In',
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward_rounded, size: 22),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.lightBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.verified_user_outlined, size: 16, color: Colors.grey.shade500),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Your credentials are encrypted & secure',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
