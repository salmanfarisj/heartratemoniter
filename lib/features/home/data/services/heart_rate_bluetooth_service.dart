import 'dart:async';
import 'dart:io' show Platform;
// flutter_blue_plus exports its own `BluetoothService` symbol — alias the
// import so it doesn't shadow our class.
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:permission_handler/permission_handler.dart';
import '../../domain/models/heart_rate_device.dart';
import '../../domain/models/device_telemetry.dart';
import 'bluetooth_permission_result.dart';

class BluetoothService {
  StreamSubscription<List<fbp.ScanResult>>? _scanSubscription;
  StreamSubscription<fbp.BluetoothConnectionState>? _deviceSubscription;

  final _scanResultsController = StreamController<List<HeartRateDevice>>.broadcast();
  Stream<List<HeartRateDevice>> get scanResults => _scanResultsController.stream;

  final _connectionStateController = StreamController<bool>.broadcast();
  Stream<bool> get connectionState => _connectionStateController.stream;

  final _heartRateController = StreamController<int>.broadcast();
  Stream<int> get heartRateStream => _heartRateController.stream;

  /// Non-HR signals the device exposes (battery %, manufacturer, sensor
  /// location). Emits whenever any of these change.
  final _telemetryController =
      StreamController<DeviceTelemetry>.broadcast();
  Stream<DeviceTelemetry> get telemetryStream => _telemetryController.stream;

  fbp.BluetoothDevice? _connectedDevice;
  fbp.BluetoothCharacteristic? _hrCharacteristic;
  fbp.BluetoothCharacteristic? _batteryCharacteristic;
  DeviceTelemetry _lastTelemetry = const DeviceTelemetry();

  // Standard BLE GATT UUIDs we care about.
  static final fbp.Guid heartRateServiceUuid =
      fbp.Guid('0000180d-0000-1000-8000-00805f9b34fb');
  static final fbp.Guid heartRateMeasurementCharUuid =
      fbp.Guid('00002a37-0000-1000-8000-00805f9b34fb');

  // Battery Service 0x180F, Battery Level 0x2A19.
  static final fbp.Guid batteryServiceUuid =
      fbp.Guid('0000180f-0000-1000-8000-00805f9b34fb');
  static final fbp.Guid batteryLevelCharUuid =
      fbp.Guid('00002a19-0000-1000-8000-00805f9b34fb');

  // Device Information Service 0x180A.
  static final fbp.Guid deviceInfoServiceUuid =
      fbp.Guid('0000180a-0000-1000-8000-00805f9b34fb');
  static final fbp.Guid manufacturerNameCharUuid =
      fbp.Guid('00002a29-0000-1000-8000-00805f9b34fb');

  // Body Sensor Location 0x2A38 (inside Heart Rate Service).
  static final fbp.Guid bodySensorLocationCharUuid =
      fbp.Guid('00002a38-0000-1000-8000-00805f9b34fb');

  /// Request every runtime permission the platform needs to scan for
  /// and connect to a BLE heart-rate monitor.
  ///
  /// Replaces the previous implementation, which silently returned
  /// `true` after probing `FlutterBluePlus.isSupported` without ever
  /// asking the user. permission_handler is the single source of truth
  /// here; flutter_blue_plus is left to deal with the actual scan.
  Future<BluetoothPermissionResult> requestPermissions() async {
    // Verify BLE is supported on the device.
    final supported = await fbp.FlutterBluePlus.isSupported;
    if (!supported) {
      return BluetoothPermissionResult.unsupported;
    }

    // iOS exposes a single "Bluetooth" usage string in Info.plist and
    // doesn't surface a runtime prompt for our use case; assume granted.
    if (!Platform.isAndroid) {
      return BluetoothPermissionResult.granted;
    }

    // Android 12+: BLUETOOTH_SCAN / BLUETOOTH_CONNECT are runtime.
    // Android <12: ACCESS_FINE_LOCATION is required to enumerate devices.
    final permissions = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ];

    final statuses = await permissions.request();

    final blocked = statuses.values.any(
      (s) => s.isPermanentlyDenied || s.isRestricted,
    );
    final denied = statuses.values.any((s) => !s.isGranted);

    if (denied) {
      return blocked
          ? BluetoothPermissionResult.permanentlyDenied
          : BluetoothPermissionResult.denied;
    }
    return BluetoothPermissionResult.granted;
  }

  /// Whether the user can recover from a permission denial by tapping
  /// "Open Settings" in the OS app.
  Future<bool> canOpenSystemSettings() async {
    if (!Platform.isAndroid) return false;
    return openAppSettings().catchError((_) => false).then((v) => v == true);
  }

  Future<bool> isBluetoothOn() async {
    try {
      final state = await fbp.FlutterBluePlus.adapterState.first;
      return state == fbp.BluetoothAdapterState.on;
    } catch (_) {
      return false;
    }
  }

  Future<void> startScan({Duration timeout = const Duration(seconds: 12)}) async {
    await _scanSubscription?.cancel();

    // Ensure the adapter is on; surface a clear error if it is off.
    final adapterState = await fbp.FlutterBluePlus.adapterState.first;
    if (adapterState != fbp.BluetoothAdapterState.on) {
      throw Exception(
        'Bluetooth is not enabled. Please turn on Bluetooth and try again.',
      );
    }

    // Scan for all BLE devices; we'll filter the results down to likely
    // heart-rate monitors in the listener below.
    await fbp.FlutterBluePlus.startScan(
      timeout: timeout,
      androidScanMode: fbp.AndroidScanMode.lowLatency,
    );

    _scanSubscription = fbp.FlutterBluePlus.scanResults.listen((results) {
      // Deduplicate by remote id (a device can show up multiple times).
      final seen = <String>{};
      final hrDevices = <HeartRateDevice>[];

      for (final r in results) {
        final id = r.device.remoteId.str;
        if (id.isEmpty || seen.contains(id)) continue;
        seen.add(id);

        // Prefer the advertised name; fall back to platform name and id.
        final advertisedName = r.advertisementData.advName.trim();
        final platformName = r.device.platformName.trim();
        final name = advertisedName.isNotEmpty
            ? advertisedName
            : (platformName.isNotEmpty
                ? platformName
                : 'Unknown Device (${id.substring(id.length - 5)})');

        if (!_isLikelyHeartRateMonitor(r.advertisementData, name)) continue;

        hrDevices.add(HeartRateDevice(
          id: id,
          name: name,
          address: id,
          rssi: r.rssi,
        ));
      }

      _scanResultsController.add(hrDevices);
    });
  }

  /// Decides whether an advertisement is likely a heart-rate monitor.
  ///
  /// Two signals, in order of authority:
  /// 1. Advertised service UUIDs include the standard BLE Heart Rate
  ///    Service (`0x180D`) — the spec-compliant way HRMs advertise.
  /// 2. A name heuristic covering common HR monitor brands, used as a
  ///    fallback for devices that broadcast a name but no service UUID.
  static bool _isLikelyHeartRateMonitor(
    fbp.AdvertisementData adv,
    String name,
  ) {
    final uuids = adv.serviceUuids;
    for (final uuid in uuids) {
      if (uuid == heartRateServiceUuid) return true;
    }

    final lower = name.toLowerCase();
    if (lower.isEmpty) return false;
    return _hrNamePatterns.any(lower.contains);
  }

  static const List<String> _hrNamePatterns = <String>[
    'polar',
    'garmin',
    'wahoo',
    'suunto',
    'fitbit',
    'coospo',
    'heart',
    'hrm',
    'h10',
    'h9',
    'h7',
    'tickr',
    'mio',
    'coros',
    'whoop',
  ];

  Future<void> stopScan() async {
    try {
      await fbp.FlutterBluePlus.stopScan();
    } catch (_) {
      // Ignore errors during stopScan.
    }
    await _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  Future<void> connect(HeartRateDevice device) async {
    await _deviceSubscription?.cancel();
    await _hrCharacteristic?.setNotifyValue(false);
    await _batteryCharacteristic?.setNotifyValue(false);
    _hrCharacteristic = null;
    _batteryCharacteristic = null;

    final bluetoothDevice = fbp.BluetoothDevice.fromId(device.address);
    await bluetoothDevice.connect(timeout: const Duration(seconds: 15));

    _connectedDevice = bluetoothDevice;

    _deviceSubscription = bluetoothDevice.connectionState.listen((state) {
      final isConnected = state == fbp.BluetoothConnectionState.connected;
      _connectionStateController.add(isConnected);
    });

    await _discoverServicesAndSubscribe(bluetoothDevice);
  }

  Future<void> _discoverServicesAndSubscribe(fbp.BluetoothDevice device) async {
    final services = await device.discoverServices();

    // Reset telemetry state per connect so we don't show stale numbers
    // if the new device doesn't expose them.
    _lastTelemetry = const DeviceTelemetry();
    _telemetryController.add(_lastTelemetry);

    for (final service in services) {
      // ---- Heart Rate Measurement (0x2A37) -----------------------------
      if (service.uuid == heartRateServiceUuid) {
        for (final char in service.characteristics) {
          if (char.uuid == heartRateMeasurementCharUuid) {
            _hrCharacteristic = char;
            await char.setNotifyValue(true);
            char.onValueReceived.listen(_onHrValueReceived);
          } else if (char.uuid == bodySensorLocationCharUuid) {
            await _readSensorLocation(char);
          }
        }
        continue;
      }

      // ---- Battery Level (0x2A19) --------------------------------------
      if (service.uuid == batteryServiceUuid) {
        for (final char in service.characteristics) {
          if (char.uuid == batteryLevelCharUuid) {
            _batteryCharacteristic = char;
            await char.setNotifyValue(true);
            char.onValueReceived.listen(_onBatteryValueReceived);
            // Most straps push a value immediately when notifications are
            // enabled; some don't, so also do an initial read as a
            // belt-and-braces fallback.
            unawaited(_readBatteryOnce(char));
          }
        }
        continue;
      }

      // ---- Device Information (0x180A) --------------------------------
      if (service.uuid == deviceInfoServiceUuid) {
        for (final char in service.characteristics) {
          if (char.uuid == manufacturerNameCharUuid) {
            await _readStringChar(char, (v) {
              _lastTelemetry = _lastTelemetry.copyWith(manufacturerName: v);
              _telemetryController.add(_lastTelemetry);
            });
          }
        }
        continue;
      }
    }
  }

  void _onHrValueReceived(List<int> value) {
    if (value.isEmpty) return;
    // HR value is typically in the second byte.
    // First byte is flags, bit 0 indicates HR format.
    final is16Bit = (value[0] & 0x01) == 1;
    final hr = is16Bit ? (value[1] | (value[2] << 8)) : value[1];
    _heartRateController.add(hr);
  }

  void _onBatteryValueReceived(List<int> value) {
    if (value.isEmpty) return;
    final pct = value[0].clamp(0, 100);
    _lastTelemetry = _lastTelemetry.copyWith(batteryPercent: pct);
    _telemetryController.add(_lastTelemetry);
  }

  Future<void> _readBatteryOnce(fbp.BluetoothCharacteristic char) async {
    try {
      final v = await char.read();
      if (v.isNotEmpty) _onBatteryValueReceived(v);
    } catch (_) {
      // Some peripherals refuse a direct read while notify is on; ignore.
    }
  }

  Future<void> _readSensorLocation(fbp.BluetoothCharacteristic char) async {
    try {
      final v = await char.read();
      if (v.isNotEmpty) {
        final loc = v[0];
        _lastTelemetry = _lastTelemetry.copyWith(sensorLocation: loc);
        _telemetryController.add(_lastTelemetry);
      }
    } catch (_) {}
  }

  Future<void> _readStringChar(
    fbp.BluetoothCharacteristic char,
    void Function(String value) onValue,
  ) async {
    try {
      final v = await char.read();
      if (v.isEmpty) return;
      // Manufacturer Name is stored as UTF-8 (0x2A29). Trim trailing NULs.
      final str = String.fromCharCodes(v.where((b) => b != 0)).trim();
      if (str.isNotEmpty) onValue(str);
    } catch (_) {}
  }

  Future<void> disconnect() async {
    try {
      await _hrCharacteristic?.setNotifyValue(false);
    } catch (_) {}
    try {
      await _batteryCharacteristic?.setNotifyValue(false);
    } catch (_) {}
    try {
      await _connectedDevice?.disconnect();
    } catch (_) {}
    await _deviceSubscription?.cancel();
    _connectedDevice = null;
    _hrCharacteristic = null;
    _batteryCharacteristic = null;
    _lastTelemetry = const DeviceTelemetry();
    _telemetryController.add(_lastTelemetry);
  }

  Future<bool> isConnected() async {
    if (_connectedDevice == null) return false;
    try {
      final state = await _connectedDevice!.connectionState.first;
      return state == fbp.BluetoothConnectionState.connected;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _scanSubscription?.cancel();
    _deviceSubscription?.cancel();
    _scanResultsController.close();
    _connectionStateController.close();
    _heartRateController.close();
    _telemetryController.close();
  }
}
