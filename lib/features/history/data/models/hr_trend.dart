import 'package:equatable/equatable.dart';

/// Time-series HR samples for the History "Heart Rate Trends" chart.
///
/// One entry per row in `live_hr_readings`, sorted oldest → newest.
/// [distanceKm] is the sum of `distance_km` across today's logged
/// activities — used by the chart's corner stat pair.
class HrTrend extends Equatable {
  final List<HrTrendSample> samples;
  final double distanceKm;

  const HrTrend({required this.samples, required this.distanceKm});

  factory HrTrend.empty() => const HrTrend(samples: [], distanceKm: 0);

  bool get isEmpty => samples.isEmpty;

  @override
  List<Object?> get props => [samples, distanceKm];
}

class HrTrendSample extends Equatable {
  final DateTime timestamp;
  final int bpm;

  const HrTrendSample({required this.timestamp, required this.bpm});

  @override
  List<Object?> get props => [timestamp, bpm];
}