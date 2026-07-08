import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const AppScaffold({
    super.key,
    required this.child,
    required this.currentPath,
  });

  /// Visible bar content height (icons + labels).
  static const double barHeight = 60;

  /// Center home button — reference ~1.43× bar height (~86px).
  static const double fabSize = 86;

  /// Side nav icon size.
  static const double navIconSize = 24;

  /// Side nav label size.
  static const double navLabelSize = 10;

  /// How much the FAB sticks above the straight bar top.
  static double get fabProtrusion => fabSize - barHeight;

  /// Clearance so bottom buttons don't sit under the center FAB.
  static double get fabOverlapClearance => fabProtrusion + 12;

  Color _barColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? AppTheme.primaryColor
        : const Color(0xFF1E293B);
  }

  bool get _isHomeActive => currentPath == '/';

  int? _getSelectedIndex() {
    if (currentPath.startsWith('/customers')) return 0;
    if (currentPath.startsWith('/enrollment')) return 1;
    if (currentPath.startsWith('/wallet')) return 2;
    if (currentPath.startsWith('/profile')) return 3;
    return null;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/customers');
        break;
      case 1:
        context.go('/enrollment');
        break;
      case 2:
        context.go('/wallet');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  Widget _buildStraightBottomBar({
    required BuildContext context,
    required Color barColor,
    required int? selectedIndex,
    required double bottomInset,
  }) {
    final totalHeight = barHeight + bottomInset;

    return Container(
      height: totalHeight,
      decoration: BoxDecoration(
        color: barColor,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Straight flat bar — nav items sit on top, no notch.
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset,
            height: barHeight,
            child: Row(
              children: [
                Expanded(
                  child: _BottomNavItem(
                    icon: Icons.people_alt_outlined,
                    activeIcon: Icons.people_alt,
                    label: 'Customers',
                    isActive: selectedIndex == 0,
                    onTap: () => _onItemTapped(0, context),
                  ),
                ),
                Expanded(
                  child: _BottomNavItem(
                    icon: Icons.assignment_outlined,
                    activeIcon: Icons.assignment,
                    label: 'Enroll',
                    isActive: selectedIndex == 1,
                    onTap: () => _onItemTapped(1, context),
                  ),
                ),
                const SizedBox(width: fabSize),
                Expanded(
                  child: _BottomNavItem(
                    icon: Icons.account_balance_wallet_outlined,
                    activeIcon: Icons.account_balance_wallet,
                    label: 'Wallet',
                    isActive: selectedIndex == 2,
                    onTap: () => _onItemTapped(2, context),
                  ),
                ),
                Expanded(
                  child: _BottomNavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Profile',
                    isActive: selectedIndex == 3,
                    onTap: () => _onItemTapped(3, context),
                  ),
                ),
              ],
            ),
          ),
          // Center home — bottom edge flush with bar bottom (screen bottom).
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _CenterHomeFab(
                isActive: _isHomeActive,
                onTap: () => context.go('/'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final barColor = _barColor(context);
    final selectedIndex = _getSelectedIndex();
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      child: Scaffold(
        body: SafeArea(top: false, bottom: false, child: child),
        bottomNavigationBar: _buildStraightBottomBar(
          context: context,
          barColor: barColor,
          selectedIndex: selectedIndex,
          bottomInset: bottomInset,
        ),
      ),
    );
  }
}

class _CenterHomeFab extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _CenterHomeFab({
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const outerWhite = 4.0;
    const lavenderRing = 3.0;
    const innerPad = 3.0;

    return SizedBox(
      width: AppScaffold.fabSize,
      height: AppScaffold.fabSize,
      child: Material(
        color: Colors.transparent,
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.75),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: const Color(0xFF93C5FD).withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(1),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.white, width: outerWhite),
              ),
              padding: const EdgeInsets.all(innerPad),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFB8C9F0),
                    width: lavenderRing,
                  ),
                ),
                padding: const EdgeInsets.all(innerPad),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? AppTheme.secondaryColor
                        : AppTheme.secondaryColor.withValues(alpha: 0.92),
                  ),
                  child: const Icon(
                    Icons.apps_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: AppScaffold.barHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.55),
              size: AppScaffold.navIconSize,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: AppScaffold.navLabelSize,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
