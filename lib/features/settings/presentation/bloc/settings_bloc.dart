import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../activities/data/repositories/activity_repository_impl.dart';
import '../../../home/data/repositories/heart_rate_repository_impl.dart';
import '../../../home/data/services/heart_rate_bluetooth_service.dart';
import '../../data/services/csv_export_service.dart';
import '../../domain/repositories/settings_repository.dart';
import 'settings_event.dart';
import 'settings_state.dart';

// ignore_for_file: prefer_initializing_formals

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _repository;
  final HeartRateRepositoryImpl _heartRateRepository;
  final ActivityRepositoryImpl _activityRepository;
  final BluetoothService _bluetoothService;
  final CsvExportService _exportService;

  SettingsBloc({
    required SettingsRepository repository,
    required HeartRateRepositoryImpl heartRateRepository,
    required ActivityRepositoryImpl activityRepository,
    required BluetoothService bluetoothService,
    CsvExportService? exportService,
  })  : _repository = repository,
        _heartRateRepository = heartRateRepository,
        _activityRepository = activityRepository,
        _bluetoothService = bluetoothService,
        _exportService = exportService ?? CsvExportService(),
        super(const SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateMaxHeartRate>(_onUpdateMaxHeartRate);
    on<AutoPromoteMaxHeartRate>(_onAutoPromoteMaxHeartRate);
    on<UpdateNotifications>(_onUpdateNotifications);
    on<UpdateUserAge>(_onUpdateUserAge);
    on<ExportData>(_onExportData);
    on<ClearAllData>(_onClearAllData);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(status: SettingsStatus.loading));
    try {
      final maxHr = await _repository.getMaxHeartRate();
      final notifications = await _repository.getNotificationsEnabled();
      final age = await _repository.getUserAge();

      emit(state.copyWith(
        status: SettingsStatus.loaded,
        maxHeartRate: maxHr,
        notificationsEnabled: notifications,
        userAge: age,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateMaxHeartRate(
    UpdateMaxHeartRate event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.setMaxHeartRate(event.value);
    emit(state.copyWith(maxHeartRate: event.value));
  }

  Future<void> _onAutoPromoteMaxHeartRate(
    AutoPromoteMaxHeartRate event,
    Emitter<SettingsState> emit,
  ) async {
    if (event.value <= state.maxHeartRate) return;
    await _repository.setMaxHeartRateInternal(event.value);
    emit(state.copyWith(maxHeartRate: event.value));
  }

  Future<void> _onUpdateNotifications(
    UpdateNotifications event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.setNotificationsEnabled(event.enabled);
    emit(state.copyWith(notificationsEnabled: event.enabled));
  }

  Future<void> _onUpdateUserAge(
    UpdateUserAge event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.setUserAge(event.age);
    final age = await _repository.getUserAge();
    // Repo re-derives max from age when the user hasn't manually pinned it.
    // Pull it back so the Settings UI reflects the new derived value.
    final maxHr = await _repository.getMaxHeartRate();
    emit(state.copyWith(userAge: age, maxHeartRate: maxHr));
  }

  Future<void> _onExportData(
    ExportData event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(status: SettingsStatus.exporting));
    try {
      final now = DateTime.now();
      String? path;
      if (event.type == 'hr' || event.type == 'all') {
        final readings = await _heartRateRepository.getReadingsInRange(
          now.subtract(const Duration(days: 30)),
          now,
        );
        path = await _exportService.exportHeartRateData(readings);
      }
      if (event.type == 'activities' || event.type == 'all') {
        final activities = await _activityRepository.getActivitiesInRange(
          now.subtract(const Duration(days: 365)),
          now,
        );
        path = await _exportService.exportActivitiesData(activities);
      }
      emit(state.copyWith(
        status: SettingsStatus.exported,
        exportedFilePath: path,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: 'Export failed: ${e.toString()}',
      ));
    }
  }

  Future<void> _onClearAllData(
    ClearAllData event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      if (await _bluetoothService.isConnected()) {
        await _bluetoothService.disconnect();
      }
      await _heartRateRepository.clearAll();
      final cleared = await _activityRepository.clearAll();
      emit(state.copyWith(
        status: SettingsStatus.loaded,
        clearedActivityCount: cleared,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: 'Clear failed: ${e.toString()}',
      ));
    }
  }
}