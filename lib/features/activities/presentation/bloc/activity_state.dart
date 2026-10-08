import 'package:equatable/equatable.dart';
import '../../domain/models/activity.dart';

enum ActivityStatus { initial, loading, loaded, error }

class ActivityState extends Equatable {
  final ActivityStatus status;
  final List<Activity> activities;
  final int todayCalories;
  final int todayDuration;
  final String? errorMessage;

  const ActivityState({
    this.status = ActivityStatus.initial,
    this.activities = const [],
    this.todayCalories = 0,
    this.todayDuration = 0,
    this.errorMessage,
  });

  ActivityState copyWith({
    ActivityStatus? status,
    List<Activity>? activities,
    int? todayCalories,
    int? todayDuration,
    String? errorMessage,
  }) {
    return ActivityState(
      status: status ?? this.status,
      activities: activities ?? this.activities,
      todayCalories: todayCalories ?? this.todayCalories,
      todayDuration: todayDuration ?? this.todayDuration,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, activities, todayCalories, todayDuration, errorMessage];
}
