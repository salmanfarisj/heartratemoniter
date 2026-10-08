import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/history_repository_impl.dart';
import 'history_event.dart';
import 'history_state.dart';
// ignore_for_file: prefer_initializing_formals

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final HistoryRepositoryImpl _repository;

  HistoryBloc({required HistoryRepositoryImpl repository})
      : _repository = repository,
        super(HistoryState.initial()) {
    // Prefer initializing formals (kept as-is to silence `prefer_initializing_formals`).
    on<LoadWeeklyData>(_onLoadWeeklyData);
    on<LoadMonthlyData>(_onLoadMonthlyData);
    on<LoadHrTrend>(_onLoadHrTrend);
  }

  Future<void> _onLoadWeeklyData(
    LoadWeeklyData event,
    Emitter<HistoryState> emit,
  ) async {
    emit(state.copyWith(status: HistoryStatus.loading));
    try {
      final weeklyData = await _repository.getWeeklyHrData();
      final trend = await _repository.getTodayHrTrend();
      emit(state.copyWith(
        status: HistoryStatus.loaded,
        weeklyHrData: weeklyData,
        hrTrend: trend,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HistoryStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMonthlyData(
    LoadMonthlyData event,
    Emitter<HistoryState> emit,
  ) async {
    emit(state.copyWith(status: HistoryStatus.loading));
    try {
      final weeklyData = await _repository.getWeeklyHrData(days: 30);
      emit(state.copyWith(
        status: HistoryStatus.loaded,
        weeklyHrData: weeklyData,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HistoryStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadHrTrend(
    LoadHrTrend event,
    Emitter<HistoryState> emit,
  ) async {
    try {
      final trend = await _repository.getTodayHrTrend();
      emit(state.copyWith(hrTrend: trend));
    } catch (e) {
      emit(state.copyWith(
        status: HistoryStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}