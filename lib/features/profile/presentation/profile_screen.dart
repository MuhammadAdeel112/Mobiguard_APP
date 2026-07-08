import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/auth_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_ui.dart';
import '../../../shared/widgets/app_scaffold.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out of the MobiGuard Sales portal?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      appBar: ReferenceAppBar.preferred(context, title: 'Agent Profile'),
      body: ReferenceBodyClip(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md + AppScaffold.fabOverlapClearance,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (user != null) ...[
                Container(
                  decoration: _cardDecoration,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          child: Text(
                            user.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              user.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
                              ),
                              child: Text(
                                user.role.replaceAll('_', ' ').toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.agentCode,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const SectionTitle(title: 'Account Details'),
                Container(
                  decoration: _cardDecoration,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Column(
                    children: [
                      _ProfileField(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: user.email,
                        iconBg: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF2563EB),
                      ),
                      _ProfileDivider(),
                      _ProfileField(
                        icon: Icons.phone_android,
                        label: 'Phone',
                        value: user.phone,
                        iconBg: const Color(0xFFECFDF5),
                        iconColor: const Color(0xFF059669),
                      ),
                      _ProfileDivider(),
                      _ProfileField(
                        icon: Icons.badge_outlined,
                        label: 'Agent Code',
                        value: user.agentCode,
                        iconBg: const Color(0xFFFFFBEB),
                        iconColor: const Color(0xFFD97706),
                      ),
                      if (user.companyId > 0) ...[
                        _ProfileDivider(),
                        _ProfileField(
                          icon: Icons.business_outlined,
                          label: 'Company ID',
                          value: '${user.companyId}',
                          iconBg: const Color(0xFFF5F3FF),
                          iconColor: const Color(0xFF7C3AED),
                        ),
                      ],
                      if (user.branchId != null) ...[
                        _ProfileDivider(),
                        _ProfileField(
                          icon: Icons.storefront_outlined,
                          label: 'Branch ID',
                          value: '${user.branchId}',
                          iconBg: const Color(0xFFE0F2FE),
                          iconColor: const Color(0xFF0284C7),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              const SectionTitle(title: 'Session'),
              Container(
                decoration: _cardDecoration,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            color: Color(0xFFDC2626),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sign out',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Log out from this device',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _handleLogout,
                        icon: const Icon(Icons.logout, size: 20),
                        label: const Text(
                          'Log Out',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(color: Color(0xFFDC2626)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.lightBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  'MobiGuard Sales v1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: Colors.grey.shade100);
  }
}

class _ProfileField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconBg;
  final Color iconColor;

  const _ProfileField({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
