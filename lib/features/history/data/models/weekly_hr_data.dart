import 'package:equatable/equatable.dart';

class WeeklyHrData extends Equatable {
  final List<int> dailyAvg;
  final List<int> dailyMax;
  final List<int> dailyMin;
  final List<String> dayLabels;

  const WeeklyHrData({
    required this.dailyAvg,
    required this.dailyMax,
    required this.dailyMin,
    required this.dayLabels,
  });

  factory WeeklyHrData.empty() {
    return const WeeklyHrData(
      dailyAvg: [],
      dailyMax: [],
      dailyMin: [],
      dayLabels: [],
    );
  }

  @override
  List<Object?> get props => [dailyAvg, dailyMax, dailyMin, dayLabels];
}
