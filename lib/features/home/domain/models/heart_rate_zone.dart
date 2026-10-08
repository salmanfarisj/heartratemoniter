import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

enum HeartRateZone {
  rest,
  fatBurn,
  cardio,
  peak;

  String get label {
    switch (this) {
      case HeartRateZone.rest:
        return 'Rest';
      case HeartRateZone.fatBurn:
        return 'Fat Burn';
      case HeartRateZone.cardio:
        return 'Cardio';
      case HeartRateZone.peak:
        return 'Peak';
    }
  }

  IconData get icon {
    switch (this) {
      case HeartRateZone.rest:
        return Icons.favorite_border;
      case HeartRateZone.fatBurn:
        return Icons.favorite_outline;
      case HeartRateZone.cardio:
        return Icons.favorite;
      case HeartRateZone.peak:
        return Icons.local_fire_department;
    }
  }

  Color get color {
    switch (this) {
      case HeartRateZone.rest:
        return AppColors.zoneRest;
      case HeartRateZone.fatBurn:
        return AppColors.zoneFatBurn;
      case HeartRateZone.cardio:
        return AppColors.zoneCardio;
      case HeartRateZone.peak:
        return AppColors.zonePeak;
    }
  }

  /// Classify a [bpm] reading into a zone. The caller passes [maxHr]; if
  /// it is null or zero, fall back to the canonical Tanaka-style default of
  /// 180 BPM so callers can never get an unclassified reading.
  static HeartRateZone fromBpm(int bpm, {int? maxHr}) {
    final effectiveMaxHr = (maxHr == null || maxHr <= 0) ? 180 : maxHr;
    final percentage = (bpm / effectiveMaxHr) * 100;

    if (percentage < 50) return HeartRateZone.rest;
    if (percentage < 70) return HeartRateZone.fatBurn;
    if (percentage < 85) return HeartRateZone.cardio;
    return HeartRateZone.peak;
  }
}