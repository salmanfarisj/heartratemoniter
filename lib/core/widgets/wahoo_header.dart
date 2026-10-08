import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import 'pulsex_logo.dart';

/// Wahoo-style page header.
///
/// Matches the Wahoo Fitness app pattern seen across all four screens
/// of the design reference: small ALL-CAPS title centred, an optional
/// leading `Back` button (iOS-style blue chevron + label) on the left,
/// and a row of action icons on the right.
///
/// Pass [title] as the natural screen name ("Running", "Workout"…) — it
/// will be uppercased and tracked to match the reference. Pass
/// [showBack] = false on tab-root screens so the leading chevron is
/// hidden. Pass [leading] to pin a widget (e.g. the PulseX brand mark)
/// to the left of the title — takes precedence over [showBack].
class WahooHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? leading;
  final double leadingSize;

  const WahooHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.showBack = false,
    this.onBack,
    this.leading,
    this.leadingSize = 36,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final hasLeading = leading != null || showBack;
    final titleInset = hasLeading ? 96.0 : 72.0;
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Centered uppercase title.
            Padding(
              padding: EdgeInsets.symmetric(horizontal: titleInset),
              child: Center(
                child: Text(
                  title.toUpperCase(),
                  style: AppTypography.appBarTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Leading back chevron (Wahoo style: blue arrow + label).
            if (leading == null && showBack)
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onBack ??
                      () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.chevron_left,
                          color: AppColors.brandBlue,
                          size: 22,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'Back',
                          style: AppTypography.body.copyWith(
                            color: AppColors.brandBlue,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Optional custom leading widget (e.g. PulseX brand mark).
            if (leading != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: SizedBox(
                    width: leadingSize,
                    height: leadingSize,
                    child: leading,
                  ),
                ),
              ),

            // Trailing action icons.
            if (actions.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Small PulseX brand mark sized to fit a WahooHeader's leading slot.
class PulseXHeaderMark extends StatelessWidget {
  final double size;
  const PulseXHeaderMark({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: PulseXHeart(size: size),
    );
  }
}