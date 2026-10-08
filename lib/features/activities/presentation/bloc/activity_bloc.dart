import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
// ignore_for_file: prefer_initializing_formals
import '../../domain/models/activity.dart';
import '../../domain/repositories/activity_repository.dart';
import 'activity_event.dart';
import 'activity_state.dart';

class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  final ActivityRepository _activityRepository;
  final _uuid = const Uuid();

  ActivityBloc({required ActivityRepository activityRepository})
      : _activityRepository = activityRepository,
        super(const ActivityState()) {
    on<LoadTodayActivities>(_onLoadTodayActivities);
    on<AddActivity>(_onAddActivity);
    on<DeleteActivity>(_onDeleteActivity);
  }

  Future<void> _onLoadTodayActivities(
    LoadTodayActivities event,
    Emitter<ActivityState> emit,
  ) async {
    emit(state.copyWith(status: ActivityStatus.loading));
    try {
      final activities = await _activityRepository.getActivitiesForDate(DateTime.now());
      final calories = await _activityRepository.getTotalCaloriesForDate(DateTime.now());
      final duration = await _activityRepository.getTotalDurationForDate(DateTime.now());

      emit(state.copyWith(
        status: ActivityStatus.loaded,
        activities: activities,
        todayCalories: calories,
        todayDuration: duration,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ActivityStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAddActivity(
    AddActivity event,
    Emitter<ActivityState> emit,
  ) async {
    try {
      final activity = Activity(
        id: _uuid.v4(),
        type: event.type,
        name: event.name,
        durationMinutes: event.durationMinutes,
        distanceKm: event.distanceKm,
        calories: event.calories,
        avgHr: event.avgHr,
        maxHr: event.maxHr,
        minHr: event.minHr,
        avgPace: event.avgPace,
        elevationGain: event.elevationGain,
        cadence: event.cadence,
        avgSpeed: event.avgSpeed,
        zone1Time: event.zone1Time,
        zone2Time: event.zone2Time,
        zone3Time: event.zone3Time,
        zone4Time: event.zone4Time,
        zone5Time: event.zone5Time,
        steps: event.steps,
        floorsClimbed: event.floorsClimbed,
        intensity: event.intensity,
        perceivedExertion: event.perceivedExertion,
        weather: event.weather,
        timestamp: DateTime.now(),
        notes: event.notes,
      );

      await _activityRepository.saveActivity(activity);
      add(LoadTodayActivities());
    } catch (e) {
      emit(state.copyWith(
        status: ActivityStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteActivity(
    DeleteActivity event,
    Emitter<ActivityState> emit,
  ) async {
    try {
      await _activityRepository.deleteActivity(event.activityId);
      add(LoadTodayActivities());
    } catch (e) {
      emit(state.copyWith(
        status: ActivityStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
