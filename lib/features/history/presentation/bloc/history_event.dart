import 'package:equatable/equatable.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadWeeklyData extends HistoryEvent {}

class LoadMonthlyData extends HistoryEvent {}

class ExportData extends HistoryEvent {}

/// Reload the dense HR time-series + today's distance for the
/// History screen's "Heart Rate Trends" chart.
class LoadHrTrend extends HistoryEvent {}