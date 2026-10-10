import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

/// Minimal three-tab navigation bar matching the PulseX reference.
///
/// A single white pill-shaped card holds three labelled tabs
/// (Workout · Record · Settings). The active tab swaps its icon
/// for a filled blue circular badge with a white glyph inside,
/// while inactive tabs show the outlined icon at silver-label grey.
/// Labels sit directly under each icon and recolour to brand blue
/// when the matching tab is active. Past sessions live under
/// Settings → Activity → History.
class ShellPage extends StatelessWidget {
  final Widget child;

  const ShellPage({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/record')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0;
  }

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/record');
        break;
      case 2:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: _MinimalBottomNav(
        selected: selected,
        onNavTap: (i) => _onNavTap(context, i),
      ),
    );
  }
}

/// Pill-shaped bottom navigation matching the reference design.
///
/// A single white card with rounded 28 px corners holds three
/// evenly-spaced tabs. Drop shadow lifts the bar off the screen
/// edge so it reads as a floating chip rather than a system bar.
class _MinimalBottomNav extends StatelessWidget {
  static const double _navHeight = 88;
  static const double _cornerRadius = 28;

  final int selected;
  final ValueChanged<int> onNavTap;

  const _MinimalBottomNav({
    required this.selected,
    required this.onNavTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: AppSpacing.md,
        ),
        child: Container(
          height: _navHeight,
          decoration: BoxDecoration(
            color: AppColors.paperWhite,
            borderRadius: BorderRadius.circular(_cornerRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavTab(
                label: 'Workout',
                active: selected == 0,
                activeIcon: Icons.fitness_center,
                inactiveIcon: Icons.fitness_center_outlined,
                onTap: () => onNavTap(0),
              ),
              _NavTab(
                label: 'Record',
                active: selected == 1,
                activeIcon: Icons.fiber_manual_record,
                inactiveIcon: Icons.radio_button_unchecked,
                onTap: () => onNavTap(1),
              ),
              _NavTab(
                label: 'Settings',
                active: selected == 2,
                activeIcon: Icons.settings,
                inactiveIcon: Icons.settings_outlined,
                onTap: () => onNavTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single tab cell inside the pill nav bar.
///
/// Inactive: outlined icon in [silverLabel] grey, with the label
/// underneath in the same grey.
///
/// Active: icon swaps to its filled variant and sits inside a
/// filled blue circle (50 px). The label recolours to brand blue
/// and bumps to semibold so the active tab reads as the primary
/// affordance.
class _NavTab extends StatelessWidget {
  final String label;
  final bool active;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final VoidCallback onTap;

  const _NavTab({
    required this.label,
    required this.active,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.onTap,
  });

  static const double _iconBadgeSize = 50;

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.brandBlue;
    final inactiveColor = AppColors.silverLabel;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconBadge(
                size: _iconBadgeSize,
                filled: active,
                color: activeColor,
                icon: active ? activeIcon : inactiveIcon,
              ),
              const SizedBox(height: AppSpacing.xs + 2),
              Text(
                label,
                style: TextStyle(
                  color: active ? activeColor : inactiveColor,
                  fontSize: 14,
                  height: 1.1,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon container that morphs between outlined-grey and
/// filled-blue-with-white-glyph depending on tab state.
class _IconBadge extends StatelessWidget {
  final double size;
  final bool filled;
  final Color color;
  final IconData icon;

  const _IconBadge({
    required this.size,
    required this.filled,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.brandBlue,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 26,
          color: AppColors.paperWhite,
        ),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Icon(
          icon,
          size: 26,
          color: color,
        ),
      ),
    );
  }
}