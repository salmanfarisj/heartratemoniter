import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Wahoo-inspired typography scale.
///
/// Matches the look observed in the Wahoo Fitness companion — short,
/// semi-bold ALL-CAPS section headers (`Inter`/`SF Pro` style), tightly
/// tracked uppercase nav-bar title, and a clean numeric display style for
/// heart-rate readings. All weights and sizes mirror the spacing scale
/// used across the app.
class AppTypography {
  AppTypography._();

  // Base text color for everything that does not override.
  static const Color _baseColor = AppColors.inkBlack;

  // ── Display (large numeric values — HR BPM, etc.) ──────────────────────
  static const TextStyle display = TextStyle(
    color: _baseColor,
    fontSize: 64,
    height: 1.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
  );

  static const TextStyle displaySm = TextStyle(
    color: _baseColor,
    fontSize: 36,
    height: 1.1,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  // ── Headings ──────────────────────────────────────────────────────────
  static const TextStyle heading = TextStyle(
    color: _baseColor,
    fontSize: 24,
    height: 1.2,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle titleLarge = TextStyle(
    color: _baseColor,
    fontSize: 17,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );

  // ── Body ──────────────────────────────────────────────────────────────
  static const TextStyle body = TextStyle(
    color: _baseColor,
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodySm = TextStyle(
    color: _baseColor,
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle caption = TextStyle(
    color: AppColors.pewter,
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w400,
  );

  // ── Buttons / chips ───────────────────────────────────────────────────
  static const TextStyle button = TextStyle(
    color: _baseColor,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static const TextStyle label = TextStyle(
    color: _baseColor,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  // ── Section headers (small caps tracking — Wahoo signature) ───────────
  static const TextStyle sectionHeader = TextStyle(
    color: AppColors.silverLabel,
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
  );

  // ── App-bar title (uppercase + tight tracking) ────────────────────────
  static const TextStyle appBarTitle = TextStyle(
    color: _baseColor,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
  );

  // ── Stat readouts (large numeric value above small caption) ───────────
  static const TextStyle statValue = TextStyle(
    color: AppColors.inkBlack,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.1,
  );

  static const TextStyle statUnit = TextStyle(
    color: AppColors.silverLabel,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.6,
  );

  static const TextStyle statLabel = TextStyle(
    color: AppColors.silverLabel,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
  );
}