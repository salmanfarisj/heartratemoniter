/// Wahoo-inspired spacing scale (base unit: 4px).
///
/// Slightly tighter than the previous Strava-style scale — Wahoo's
/// running app uses ~12-16px screen gutters and ~12-16px between cards.
class AppSpacing {
  AppSpacing._();

  static const double unit = 4.0;

  static const double xs = 4.0;     //  4px
  static const double sm = 8.0;     //  8px
  static const double md = 12.0;    // 12px
  static const double lg = 16.0;    // 16px — Wahoo screen edge gutter
  static const double xl = 20.0;    // 20px
  static const double xxl = 24.0;   // 24px — between stacked cards
  static const double xxxl = 32.0;  // 32px
  static const double huge = 48.0;  // 48px
}