/// Wahoo-inspired border-radius scale.
///
/// Cards use a soft 12px corner — Wahoo's signature chip-card style.
/// Pills/segmented controls are fully rounded (999). Inputs/buttons are
/// 8px.
class AppRadius {
  AppRadius._();

  static const double tags = 4.0;
  static const double inputs = 8.0;
  static const double buttons = 8.0;
  static const double cards = 12.0; // primary card radius
  static const double sm = 6.0;
  static const double md = 10.0;
  static const double pill = 999.0;
}