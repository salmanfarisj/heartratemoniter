import 'package:equatable/equatable.dart';

/// Snapshot of non-HR data exposed by the BLE peripheral.
///
/// Most heart-rate straps do *not* expose battery as a percentage — they
/// advertise the Battery Service (`0x180F`) only when the implementation
/// chooses to. Anything that wasn't reported by the device is `null`.
class DeviceTelemetry extends Equatable {
  /// 0–100 if Battery Service characteristic `0x2A19` is present.
  final int? batteryPercent;

  /// Raw ASCII from Manufacturer Name String `0x2A29`, if advertised.
  final String? manufacturerName;

  /// Body Sensor Location enum `0x2A38`: 0=other, 1=chest, 2=wrist,
  /// 3=finger, 4=hand, 5=earlobe, 6=foot. Null if unsupported.
  final int? sensorLocation;

  const DeviceTelemetry({
    this.batteryPercent,
    this.manufacturerName,
    this.sensorLocation,
  });

  DeviceTelemetry copyWith({
    int? batteryPercent,
    String? manufacturerName,
    int? sensorLocation,
  }) {
    return DeviceTelemetry(
      batteryPercent: batteryPercent ?? this.batteryPercent,
      manufacturerName: manufacturerName ?? this.manufacturerName,
      sensorLocation: sensorLocation ?? this.sensorLocation,
    );
  }

  @override
  List<Object?> get props => [batteryPercent, manufacturerName, sensorLocation];
}