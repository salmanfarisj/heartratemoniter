import 'package:equatable/equatable.dart';
import '../../domain/models/heart_rate_device.dart';
import '../../domain/models/device_telemetry.dart';

abstract class HeartRateEvent extends Equatable {
  const HeartRateEvent();

  @override
  List<Object?> get props => [];
}

class StartScan extends HeartRateEvent {}

class StopScan extends HeartRateEvent {}

class ConnectToDevice extends HeartRateEvent {
  final HeartRateDevice device;
  const ConnectToDevice(this.device);

  @override
  List<Object?> get props => [device];
}

class DisconnectDevice extends HeartRateEvent {}

class HeartRateUpdated extends HeartRateEvent {
  final int bpm;
  const HeartRateUpdated(this.bpm);

  @override
  List<Object?> get props => [bpm];
}

/// Non-HR signals from the strap: battery %, manufacturer, sensor
/// location. Pushed whenever any value changes.
class DeviceTelemetryUpdated extends HeartRateEvent {
  final DeviceTelemetry telemetry;
  const DeviceTelemetryUpdated(this.telemetry);

  @override
  List<Object?> get props => [telemetry];
}

class ConnectionStateChanged extends HeartRateEvent {
  final bool isConnected;
  const ConnectionStateChanged(this.isConnected);

  @override
  List<Object?> get props => [isConnected];
}

class LoadTodayStats extends HeartRateEvent {}

class ScanResultsUpdated extends HeartRateEvent {
  final List<HeartRateDevice> devices;
  const ScanResultsUpdated(this.devices);

  @override
  List<Object?> get props => [devices];
}

/// Pushed by the SettingsBloc → HomePage listener whenever the user
/// updates their configured max heart rate.
class MaxHeartRateChanged extends HeartRateEvent {
  final int value;
  const MaxHeartRateChanged(this.value);

  @override
  List<Object?> get props => [value];
}

/// User tapped "Open Settings" after a permanent permission denial.
class PermissionDeniedOpenSettings extends HeartRateEvent {}