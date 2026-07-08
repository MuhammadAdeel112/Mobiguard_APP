import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

/// Shared spacing and radius tokens for consistent UI.
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double radius = 12;
  static const double radiusLg = 16;
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: AppTheme.primaryColor.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorBanner({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          if (onRetry != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.redAccent, size: 20),
              onPressed: onRetry,
            ),
        ],
      ),
    );
  }
}

class ListSkeleton extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const ListSkeleton({super.key, this.itemCount = 5, this.itemHeight = 72});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final highlight = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, __) => Container(
        height: itemHeight,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Row(
          children: [
            const SizedBox(width: AppSpacing.md),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: highlight, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    width: 140,
                    decoration: BoxDecoration(color: highlight, borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    height: 10,
                    width: 90,
                    decoration: BoxDecoration(color: highlight, borderRadius: BorderRadius.circular(4)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.filled = false,
  });

  factory StatusChip.fromStatus(String status, {bool filled = false}) {
    final normalized = status.toLowerCase();
    final isPositive = normalized == 'active' || normalized == 'approved' || normalized == 'completed' || normalized == 'paid';
    final isPending = normalized == 'pending' || normalized == 'inactive';
    final color = isPositive
        ? Colors.green
        : isPending
            ? Colors.orange
            : Colors.redAccent;
    return StatusChip(label: status.toUpperCase(), color: color, filled: filled);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: filled ? null : Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: filled ? Colors.white : color,
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionTitle({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> labels;

  const StepIndicator({super.key, required this.currentStep, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: List.generate(labels.length * 2 - 1, (index) {
          if (index.isOdd) {
            final stepIndex = index ~/ 2;
            final done = stepIndex < currentStep;
            return Expanded(
              child: Container(
                height: 2,
                color: done ? AppTheme.primaryColor : Colors.grey.shade300,
              ),
            );
          }
          final stepIndex = index ~/ 2;
          final active = stepIndex == currentStep;
          final done = stepIndex < currentStep;
          return Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done || active ? AppTheme.primaryColor : Colors.grey.shade300,
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text(
                          '${stepIndex + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: active ? Colors.white : Colors.grey.shade600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                labels[stepIndex],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.bold : FontWeight.w500,
                  color: active ? AppTheme.primaryColor : Colors.grey.shade600,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color background;
  final Color iconColor;
  final VoidCallback onTap;
  final bool enabled;

  const QuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    required this.background,
    required this.iconColor,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600, height: 1.2),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;
  final VoidCallback? onTap;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: color, size: 22),
                  const SizedBox(height: 6),
                ],
                Text(
                  value,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reference-style header only — solid navy bar, centered title, status bar integrated.
class ReferenceAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;

  const ReferenceAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
  });

  static const double toolbarHeight = 56;

  static PreferredSizeWidget preferred(
    BuildContext context, {
    required String title,
    String? subtitle,
    Widget? leading,
    List<Widget> actions = const [],
  }) {
    final topInset = MediaQuery.paddingOf(context).top;
    return PreferredSize(
      preferredSize: Size.fromHeight(topInset + toolbarHeight),
      child: ReferenceAppBar(
        title: title,
        subtitle: subtitle,
        leading: leading,
        actions: actions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final headerColor = isLight ? AppTheme.primaryColor : const Color(0xFF1E293B);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Container(
        color: headerColor,
        padding: EdgeInsets.only(top: topInset),
        child: NavigationToolbar(
          leading: leading,
          middle: subtitle != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                )
              : Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          trailing: actions.isNotEmpty
              ? Row(mainAxisSize: MainAxisSize.min, children: actions)
              : null,
          centerMiddle: true,
        ),
      ),
    );
  }
}

/// Rounds only the top of the body so it tucks under the header (reference curve).
class ReferenceBodyClip extends StatelessWidget {
  final Widget child;

  const ReferenceBodyClip({super.key, required this.child});

  static const double topRadius = 28;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(topRadius)),
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: child,
        ),
      ),
    );
  }
}
