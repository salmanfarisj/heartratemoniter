import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/heart_rate_device.dart';
import '../../domain/models/device_telemetry.dart';
import '../../domain/models/heart_rate_zone.dart';
import '../../domain/repositories/heart_rate_repository.dart';
import '../../../settings/domain/repositories/settings_repository.dart';
import '../../data/services/heart_rate_bluetooth_service.dart';
import '../../data/services/bluetooth_permission_result.dart';
import 'heart_rate_event.dart';
import 'heart_rate_state.dart';
// ignore_for_file: prefer_initializing_formals

/// Heart-rate UI state machine.
///
/// The previous implementation wrote one row per BLE sample (1 Hz) which
/// meant ~86 400 rows per day and a slow DB scan for every stats query.
/// Now:
/// - The live UI reads only in-memory state.
/// - Once per second the bloc flushes a single aggregate into
///   `daily_hr_aggregates` via the repository (SQL upsert with MIN/MAX/SUM).
/// - Stats queries hit a single row in `daily_hr_aggregates`; no rows are
///   materialized in Dart.
class HeartRateBloc extends Bloc<HeartRateEvent, HeartRateState> {
  final HeartRateRepository _heartRateRepository;
  final BluetoothService _bluetoothService;
  final SettingsRepository _settingsRepository;

  /// Called when a sustained high reading auto-promotes max HR. Wired in
  /// `main.dart` to dispatch `SettingsBloc.add(AutoPromoteMaxHeartRate(v))`
  /// so the Settings UI mirrors the change without circular subscriptions.
  final void Function(int value) _onAutoPromoted;

  StreamSubscription<int>? _hrSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<List<HeartRateDevice>>? _scanSubscription;
  StreamSubscription<DeviceTelemetry>? _telemetrySubscription;

  Timer? _aggregateFlushTimer;
  int? _pendingBpm;
  HeartRateZone? _pendingZone;

  /// Consecutive live samples whose bpm exceeded the configured max. Reset
  /// on any sample at-or-below max. When this reaches
  /// [_sustainedHighThreshold] (3 ≈ 3 seconds at 1 Hz BLE rate) we dispatch
  /// the auto-promote event. Counter resets after the promote fires.
  int _sustainedHighCount = 0;

  /// Number of consecutive over-max samples required before the bloc
  /// triggers an auto-promotion. At 1 Hz this is ~3 seconds.
  static const int _sustainedHighThreshold = 3;

  HeartRateBloc({
    required HeartRateRepository heartRateRepository,
    required BluetoothService bluetoothService,
    required SettingsRepository settingsRepository,
    void Function(int value)? onAutoPromoted,
  })  : _heartRateRepository = heartRateRepository,
        _bluetoothService = bluetoothService,
        _settingsRepository = settingsRepository,
        _onAutoPromoted = onAutoPromoted ?? _noopOnPromoted,
        super(const HeartRateState()) {
    on<StartScan>(_onStartScan);
    on<StopScan>(_onStopScan);
    on<ConnectToDevice>(_onConnectToDevice);
    on<DisconnectDevice>(_onDisconnectDevice);
    on<HeartRateUpdated>(_onHeartRateUpdated);
    on<DeviceTelemetryUpdated>(_onDeviceTelemetryUpdated);
    on<ConnectionStateChanged>(_onConnectionStateChanged);
    on<LoadTodayStats>(_onLoadTodayStats);
    on<ScanResultsUpdated>(_onScanResultsUpdated);
    on<MaxHeartRateChanged>(_onMaxHeartRateChanged);
    on<PermissionDeniedOpenSettings>(_onPermissionDeniedOpenSettings);
    on<_AggregateTick>(_onAggregateTick);
    on<_PromoteMaxHeartRate>(_onPromoteMaxHeartRate);

    _setupStreams();
  }

  static void _noopOnPromoted(int value) {}

  void _setupStreams() {
    _hrSubscription = _bluetoothService.heartRateStream.listen((bpm) {
      add(HeartRateUpdated(bpm));
    });

    _connectionSubscription =
        _bluetoothService.connectionState.listen((isConnected) {
      add(ConnectionStateChanged(isConnected));
    });

    _scanSubscription = _bluetoothService.scanResults.listen((devices) {
      add(ScanResultsUpdated(devices));
    });

    _telemetrySubscription =
        _bluetoothService.telemetryStream.listen((t) {
      add(DeviceTelemetryUpdated(t));
    });
  }

  Future<void> _onStartScan(StartScan event, Emitter<HeartRateState> emit) async {
    final result = await _bluetoothService.requestPermissions();
    if (result != BluetoothPermissionResult.granted) {
      emit(state.copyWith(
        isScanning: false,
        scanStatus: ScanStatus.error,
        permissionResult: result,
      ));
      return;
    }

    emit(state.copyWith(
      isScanning: true,
      scanStatus: ScanStatus.scanning,
      discoveredDevices: const [],
      clearError: true,
      clearPermissionResult: true,
    ));

    try {
      await _bluetoothService.startScan();
    } catch (e) {
      emit(state.copyWith(
        isScanning: false,
        scanStatus: ScanStatus.error,
        errorMessage: _friendlyError(e.toString()),
      ));
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('Bluetooth is not enabled')) {
      return 'Bluetooth is off. Please turn it on and try again.';
    }
    if (raw.contains('BLUETOOTH_SCAN') || raw.contains('BLUETOOTH_CONNECT')) {
      return 'Bluetooth permission denied. Please grant it in Settings.';
    }
    if (raw.contains('Location')) {
      return 'Location permission required for BLE scanning on older Android.';
    }
    return raw;
  }

  Future<void> _onStopScan(StopScan event, Emitter<HeartRateState> emit) async {
    await _bluetoothService.stopScan();
    emit(state.copyWith(
      isScanning: false,
      scanStatus: ScanStatus.idle,
    ));
  }

  Future<void> _onConnectToDevice(
    ConnectToDevice event,
    Emitter<HeartRateState> emit,
  ) async {
    emit(state.copyWith(isScanning: false));
    await _bluetoothService.stopScan();

    try {
      await _bluetoothService.connect(event.device);
      emit(state.copyWith(
        connectedDevice: event.device,
        isConnected: true,
        scanStatus: ScanStatus.idle,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to connect: ${e.toString()}',
      ));
    }
  }

  Future<void> _onDisconnectDevice(
    DisconnectDevice event,
    Emitter<HeartRateState> emit,
  ) async {
    _stopFlushTimer();
    await _flushPendingAggregate();
    await _bluetoothService.disconnect();
    emit(state.copyWith(
      isConnected: false,
      clearConnectedDevice: true,
      clearCurrentBpm: true,
    ));
  }

  void _onHeartRateUpdated(
    HeartRateUpdated event,
    Emitter<HeartRateState> emit,
  ) {
    final zone = HeartRateZone.fromBpm(
      event.bpm,
      maxHr: state.maxHeartRate,
    );
    _pendingBpm = event.bpm;
    _pendingZone = zone;
    _ensureFlushTimer();

    // Sustained-high auto-promotion gate: only fire after 3 consecutive
    // samples above the current max. Single-sample spikes (sensor noise)
    // are ignored. Counter resets on every sample at-or-below max.
    if (event.bpm > state.maxHeartRate) {
      _sustainedHighCount++;
      if (_sustainedHighCount >= _sustainedHighThreshold) {
        add(_PromoteMaxHeartRate(event.bpm));
      }
    } else {
      _sustainedHighCount = 0;
    }

    emit(state.copyWith(currentBpm: event.bpm));
  }

  void _ensureFlushTimer() {
    if (_aggregateFlushTimer != null) return;
    _aggregateFlushTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(const _AggregateTick()),
    );
  }

  void _stopFlushTimer() {
    _aggregateFlushTimer?.cancel();
    _aggregateFlushTimer = null;
  }

  /// Writes the most recent bpm to the daily aggregate for the *current*
  /// second. Routed through a private event so the emit happens inside
  /// the bloc handler, not inside a timer callback.
  Future<void> _onAggregateTick(
    _AggregateTick event,
    Emitter<HeartRateState> emit,
  ) async {
    final bpm = _pendingBpm;
    final zone = _pendingZone;
    if (bpm == null || zone == null) return;
    final now = DateTime.now();
    final secondBucket = DateTime(now.year, now.month, now.day, now.hour,
        now.minute, now.second);
    try {
      await _heartRateRepository.recordAggregated(
        second: secondBucket,
        bpm: bpm,
        zone: zone,
      );
      final stats = await _heartRateRepository.getStatsForDate(DateTime.now());
      emit(state.copyWith(todayStats: stats));
    } catch (_) {
      // Drop transient DB errors; the next tick will retry.
    }
  }

  Future<void> _flushPendingAggregate() async {
    final bpm = _pendingBpm;
    final zone = _pendingZone;
    if (bpm == null || zone == null) return;
    try {
      await _heartRateRepository.recordAggregated(
        second: DateTime.now(),
        bpm: bpm,
        zone: zone,
      );
    } catch (_) {
      // Best-effort on disconnect.
    }
  }

  void _onConnectionStateChanged(
    ConnectionStateChanged event,
    Emitter<HeartRateState> emit,
  ) {
    if (!event.isConnected && state.isConnected) {
      _stopFlushTimer();
      _flushPendingAggregate();
      _sustainedHighCount = 0;
      emit(state.copyWith(
        isConnected: false,
        clearCurrentBpm: true,
        telemetry: const DeviceTelemetry(),
      ));
    }
  }

  void _onDeviceTelemetryUpdated(
    DeviceTelemetryUpdated event,
    Emitter<HeartRateState> emit,
  ) {
    emit(state.copyWith(telemetry: event.telemetry));
  }

  Future<void> _onLoadTodayStats(
    LoadTodayStats event,
    Emitter<HeartRateState> emit,
  ) async {
    final stats = await _heartRateRepository.getStatsForDate(DateTime.now());
    emit(state.copyWith(todayStats: stats));
  }

  void _onScanResultsUpdated(
    ScanResultsUpdated event,
    Emitter<HeartRateState> emit,
  ) {
    if (state.isScanning) {
      emit(state.copyWith(
        discoveredDevices: event.devices,
        scanStatus: ScanStatus.found,
      ));
    }
  }

  void _onMaxHeartRateChanged(
    MaxHeartRateChanged event,
    Emitter<HeartRateState> emit,
  ) {
    if (event.value == state.maxHeartRate) return;
    emit(state.copyWith(maxHeartRate: event.value));
  }

  /// Persist the new max HR (capped), notify the SettingsBloc, and update
  /// own state so subsequent zone classifications use the new ceiling.
  /// Uses [SettingsRepository.setMaxHeartRateInternal] so the user-set
  /// flag is preserved — a future age change can still re-derive max.
  Future<void> _onPromoteMaxHeartRate(
    _PromoteMaxHeartRate event,
    Emitter<HeartRateState> emit,
  ) async {
    final capped = event.bpm > SettingsRepository.maxHeartRateCap
        ? SettingsRepository.maxHeartRateCap
        : event.bpm;
    if (capped <= state.maxHeartRate) {
      _sustainedHighCount = 0;
      return;
    }
    try {
      await _settingsRepository.setMaxHeartRateInternal(capped);
    } catch (_) {
      // Best-effort persist; do not crash the live stream on DB error.
    }
    // Reset gate *before* emitting so the next sample doesn't immediately
    // re-fire the same promotion.
    _sustainedHighCount = 0;
    emit(state.copyWith(maxHeartRate: capped));
    _onAutoPromoted(capped);
  }

  void _onPermissionDeniedOpenSettings(
    PermissionDeniedOpenSettings event,
    Emitter<HeartRateState> emit,
  ) {
    emit(state.copyWith(
      clearPermissionResult: true,
      clearError: true,
    ));
  }

  @override
  Future<void> close() {
    _stopFlushTimer();
    _hrSubscription?.cancel();
    _connectionSubscription?.cancel();
    _scanSubscription?.cancel();
    _telemetrySubscription?.cancel();
    return super.close();
  }
}

/// Internal event used by the 1Hz flush timer. Kept private so external
/// callers cannot trigger flushes manually.
class _AggregateTick extends HeartRateEvent {
  const _AggregateTick();
}

/// Internal event fired by [HeartRateBloc._onHeartRateUpdated] once the
/// sustained-high gate trips. Kept private so callers can't spam
/// promotions manually.
class _PromoteMaxHeartRate extends HeartRateEvent {
  final int bpm;
  const _PromoteMaxHeartRate(this.bpm);

  @override
  List<Object?> get props => [bpm];
}