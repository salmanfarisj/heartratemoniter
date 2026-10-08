import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {}

class UpdateMaxHeartRate extends SettingsEvent {
  final int value;
  const UpdateMaxHeartRate(this.value);

  @override
  List<Object?> get props => [value];
}

/// Pushed by [HeartRateBloc] when live HR stays above the configured max
/// for ≥ 3 consecutive samples. Stores the value via
/// [SettingsRepository.setMaxHeartRateInternal] so the user-set flag is
/// preserved (a later age change can still re-compute Max from the stored age).
class AutoPromoteMaxHeartRate extends SettingsEvent {
  final int value;
  const AutoPromoteMaxHeartRate(this.value);

  @override
  List<Object?> get props => [value];
}

class UpdateNotifications extends SettingsEvent {
  final bool enabled;
  const UpdateNotifications(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class UpdateUserAge extends SettingsEvent {
  final int age;
  const UpdateUserAge(this.age);

  @override
  List<Object?> get props => [age];
}

class ExportData extends SettingsEvent {
  final String type; // 'hr', 'activities', 'all'
  const ExportData(this.type);

  @override
  List<Object?> get props => [type];
}

class ClearAllData extends SettingsEvent {}
