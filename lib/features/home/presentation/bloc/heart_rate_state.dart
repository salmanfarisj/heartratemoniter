import 'package:equatable/equatable.dart';
import '../../data/services/bluetooth_permission_result.dart';
import '../../domain/models/heart_rate_device.dart';
import '../../domain/models/heart_rate_stats.dart';
import '../../domain/models/device_telemetry.dart';

enum ScanStatus { idle, scanning, found, error }

class HeartRateState extends Equatable {
  final int? currentBpm;
  final bool isConnected;
  final bool isScanning;
  final ScanStatus scanStatus;
  final List<HeartRateDevice> discoveredDevices;
  final HeartRateDevice? connectedDevice;
  final HeartRateStats todayStats;
  final String? errorMessage;

  /// Non-HR data the strap exposes (battery, manufacturer, sensor
  /// location). Nulls inside [telemetry] mean the device didn't report
  /// that field rather than "we forgot to read it".
  final DeviceTelemetry telemetry;

  /// Max HR configured by the user. Used by `HeartRateZone.fromBpm` to
  /// classify readings into the correct zone.
  final int maxHeartRate;

  /// Latest permission probe result, surfaced so the UI can show
  /// "Open Settings" affordances when the user has permanently denied a
  /// permission.
  final BluetoothPermissionResult? permissionResult;

  const HeartRateState({
    this.currentBpm,
    this.isConnected = false,
    this.isScanning = false,
    this.scanStatus = ScanStatus.idle,
    this.discoveredDevices = const [],
    this.connectedDevice,
    this.todayStats = const HeartRateStats.empty(),
    this.errorMessage,
    this.telemetry = const DeviceTelemetry(),
    this.maxHeartRate = 180,
    this.permissionResult,
  });

  HeartRateState copyWith({
    int? currentBpm,
    bool? isConnected,
    bool? isScanning,
    ScanStatus? scanStatus,
    List<HeartRateDevice>? discoveredDevices,
    HeartRateDevice? connectedDevice,
    HeartRateStats? todayStats,
    String? errorMessage,
    DeviceTelemetry? telemetry,
    int? maxHeartRate,
    BluetoothPermissionResult? permissionResult,
    bool clearCurrentBpm = false,
    bool clearError = false,
    bool clearConnectedDevice = false,
    bool clearPermissionResult = false,
  }) {
    return HeartRateState(
      currentBpm: clearCurrentBpm ? null : (currentBpm ?? this.currentBpm),
      isConnected: isConnected ?? this.isConnected,
      isScanning: isScanning ?? this.isScanning,
      scanStatus: scanStatus ?? this.scanStatus,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      connectedDevice:
          clearConnectedDevice ? null : (connectedDevice ?? this.connectedDevice),
      todayStats: todayStats ?? this.todayStats,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      telemetry: telemetry ?? this.telemetry,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
      permissionResult:
          clearPermissionResult ? null : (permissionResult ?? this.permissionResult),
    );
  }

  @override
  List<Object?> get props => [
        currentBpm,
        isConnected,
        isScanning,
        scanStatus,
        discoveredDevices,
        connectedDevice,
        todayStats,
        errorMessage,
        telemetry,
        maxHeartRate,
        permissionResult,
      ];
}