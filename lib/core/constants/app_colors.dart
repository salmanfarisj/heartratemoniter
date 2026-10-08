import 'package:flutter/material.dart';

/// PulseX brand palette.
///
/// Mirrors the gradient stack from the official PulseX mark:
/// cyan (`#55F0C4`) → azure (`#00AAFF`) → blue (`#145CFF`), with a deep
/// ink-black (`#050609`) used for the heart's negative space. Wahoo's
/// vivid accent is kept as a fallback so existing call sites continue to
/// read sensibly.
class AppColors {
  AppColors._();

  // ── PulseX gradient stops ─────────────────────────────────────────────
  static const Color pulsexMint = Color(0xFF55F0C4);
  static const Color pulsexAzure = Color(0xFF00AAFF);
  static const Color pulsexBlue = Color(0xFF145CFF);
  static const Color pulsexInk = Color(0xFF050609);

  /// Default PulseX gradient (left-to-right, mint → blue).
  static const LinearGradient pulsexGradient = LinearGradient(
    colors: [pulsexMint, pulsexAzure, pulsexBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Primary accents (PulseX blue, replaces old Wahoo blue) ───────────
  static const Color brandBlue = pulsexBlue;
  static const Color brandBlueDark = Color(0xFF0F44B8);
  static const Color brandBlueTint = Color(0xFFE4EEFF);

  // ── Surfaces ──────────────────────────────────────────────────────────
  static const Color paperWhite = Color(0xFFFFFFFF);
  static const Color warmLinen = Color(0xFFF7F9FC); // card tinted bg
  static const Color pillGrey = Color(0xFFF2F4F7);

  // ── Text ──────────────────────────────────────────────────────────────
  static const Color inkBlack = Color(0xFF1A1A1A);
  static const Color charcoal = Color(0xFF333333);
  static const Color graphite = Color(0xFF555555);
  static const Color pewter = Color(0xFF777777);
  static const Color silverLabel = Color(0xFF8A8A8A);

  // ── Borders / dividers ───────────────────────────────────────────────
  static const Color hairline = Color(0xFFE5E5E5);
  static const Color bone = Color(0xFFEDEDED);

  // ── Heart rate chart fill (PulseX red → still the live HR accent) ───
  static const Color hrChartFill = Color(0xFFE54848);
  static const Color hrChartFillSoft = Color(0x33E54848);

  // ── Heart Rate Zones ──────────────────────────────────────────────────
  static const Color zoneRest = Color(0xFF4CAF50);
  static const Color zoneFatBurn = Color(0xFFFFC107);
  static const Color zoneCardio = Color(0xFFFF9800);
  static const Color zonePeak = Color(0xFFE54848);

  // ── Status accents used by pill chips ────────────────────────────────
  static const Color successGreen = Color(0xFF22A06B);
  static const Color warningAmber = Color(0xFFF5A623);
}
