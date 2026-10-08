import 'package:equatable/equatable.dart';
import '../../data/models/hr_trend.dart';
import '../../data/models/weekly_hr_data.dart';

enum HistoryStatus { initial, loading, loaded, error }

class HistoryState extends Equatable {
  final HistoryStatus status;
  final WeeklyHrData weeklyHrData;
  final HrTrend hrTrend;
  final String? errorMessage;

  const HistoryState({
    this.status = HistoryStatus.initial,
    required this.weeklyHrData,
    required this.hrTrend,
    this.errorMessage,
  });

  factory HistoryState.initial() {
    return HistoryState(
      status: HistoryStatus.initial,
      weeklyHrData: WeeklyHrData.empty(),
      hrTrend: HrTrend.empty(),
    );
  }

  HistoryState copyWith({
    HistoryStatus? status,
    WeeklyHrData? weeklyHrData,
    HrTrend? hrTrend,
    String? errorMessage,
  }) {
    return HistoryState(
      status: status ?? this.status,
      weeklyHrData: weeklyHrData ?? this.weeklyHrData,
      hrTrend: hrTrend ?? this.hrTrend,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, weeklyHrData, hrTrend, errorMessage];
}