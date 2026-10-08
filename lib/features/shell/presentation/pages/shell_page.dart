import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/pulsex_logo.dart';

/// Wahoo-inspired bottom navigation with a centred "Record" action.
///
/// Four slots surrounding a FAB-style centre button:
///   Workout · History · [ + ] · Settings
///
/// The centre is rendered as a circular Wahoo-blue button that floats
/// above the bar (Instagram-style notch) and opens the activity-log
/// form. The other four slots use outlined glyphs and Wahoo-blue when
/// active.
class ShellPage extends StatelessWidget {
  final Widget child;

  const ShellPage({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/history')) return 1;
    if (location.startsWith('/record')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/history');
        break;
      case 2:
        context.go('/record');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.hairline, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _calculateSelectedIndex(context),
          onTap: (index) => _onItemTapped(context, index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.paperWhite,
          selectedItemColor: AppColors.brandBlue,
          unselectedItemColor: AppColors.silverLabel,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          iconSize: 22,
          // 4 visible items + 1 empty centre slot for the FAB.
          items: [
            BottomNavigationBarItem(
              icon: _NavMark(active: false),
              activeIcon: _NavMark(active: true),
              label: 'Workout',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.show_chart_outlined),
              activeIcon: Icon(Icons.show_chart),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: SizedBox.shrink(),
              activeIcon: SizedBox.shrink(),
              label: 'Record',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
      floatingActionButton: _RecordFab(
        onTap: () => context.go('/record'),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
    );
  }
}

/// Centre "+ Record" pill — Wahoo-blue circle that opens the
/// activity-log screen.
class _RecordFab extends StatelessWidget {
  final VoidCallback onTap;
  const _RecordFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: 60,
      child: FloatingActionButton(
        heroTag: 'record-fab',
        backgroundColor: AppColors.brandBlue,
        foregroundColor: AppColors.paperWhite,
        elevation: 4,
        shape: const CircleBorder(),
        onPressed: onTap,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

/// PulseX heart mark for the bottom-nav Workout tab. Renders the brand
/// heart in PulseX blue when the tab is active, and silver when not.
class _NavMark extends StatelessWidget {
  final bool active;
  const _NavMark({required this.active});

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        active ? AppColors.brandBlue : AppColors.silverLabel,
        BlendMode.srcIn,
      ),
      child: PulseXHeart(size: 22),
    );
  }
}