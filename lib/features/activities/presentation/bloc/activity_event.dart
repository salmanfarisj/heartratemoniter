import 'package:equatable/equatable.dart';
import '../../domain/models/activity.dart';
import '../../domain/models/activity_type.dart';

abstract class ActivityEvent extends Equatable {
  const ActivityEvent();

  @override
  List<Object?> get props => [];
}

class LoadTodayActivities extends ActivityEvent {}

class AddActivity extends ActivityEvent {
  final ActivityType type;
  final String name;
  final int durationMinutes;
  final double? distanceKm;
  final int? calories;
  final int? avgHr;
  final int? maxHr;
  final int? minHr;
  final double? avgPace;
  final double? elevationGain;
  final int? cadence;
  final double? avgSpeed;
  final int? zone1Time;
  final int? zone2Time;
  final int? zone3Time;
  final int? zone4Time;
  final int? zone5Time;
  final int? steps;
  final int? floorsClimbed;
  final ActivityIntensity? intensity;
  final int? perceivedExertion;
  final String? weather;
  final String? notes;

  const AddActivity({
    required this.type,
    required this.name,
    required this.durationMinutes,
    this.distanceKm,
    this.calories,
    this.avgHr,
    this.maxHr,
    this.minHr,
    this.avgPace,
    this.elevationGain,
    this.cadence,
    this.avgSpeed,
    this.zone1Time,
    this.zone2Time,
    this.zone3Time,
    this.zone4Time,
    this.zone5Time,
    this.steps,
    this.floorsClimbed,
    this.intensity,
    this.perceivedExertion,
    this.weather,
    this.notes,
  });

  @override
  List<Object?> get props => [
        type,
        name,
        durationMinutes,
        distanceKm,
        calories,
        avgHr,
        maxHr,
        minHr,
        avgPace,
        elevationGain,
        cadence,
        avgSpeed,
        zone1Time,
        zone2Time,
        zone3Time,
        zone4Time,
        zone5Time,
        steps,
        floorsClimbed,
        intensity,
        perceivedExertion,
        weather,
        notes,
      ];
}

class DeleteActivity extends ActivityEvent {
  final String activityId;
  const DeleteActivity(this.activityId);

  @override
  List<Object?> get props => [activityId];
}
