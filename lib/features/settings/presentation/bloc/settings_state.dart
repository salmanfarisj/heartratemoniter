import 'package:equatable/equatable.dart';

enum SettingsStatus { initial, loading, loaded, error, exporting, exported }

class SettingsState extends Equatable {
  final SettingsStatus status;
  final int maxHeartRate;
  final bool notificationsEnabled;
  final int userAge;
  final String? exportedFilePath;
  final int? clearedActivityCount;
  final String? errorMessage;

  const SettingsState({
    this.status = SettingsStatus.initial,
    this.maxHeartRate = 180,
    this.notificationsEnabled = true,
    this.userAge = 30,
    this.exportedFilePath,
    this.clearedActivityCount,
    this.errorMessage,
  });

  SettingsState copyWith({
    SettingsStatus? status,
    int? maxHeartRate,
    bool? notificationsEnabled,
    int? userAge,
    String? exportedFilePath,
    int? clearedActivityCount,
    String? errorMessage,
    bool clearError = false,
    bool clearExportPath = false,
    bool clearClearedCount = false,
  }) {
    return SettingsState(
      status: status ?? this.status,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      userAge: userAge ?? this.userAge,
      exportedFilePath:
          clearExportPath ? null : (exportedFilePath ?? this.exportedFilePath),
      clearedActivityCount: clearClearedCount
          ? null
          : (clearedActivityCount ?? this.clearedActivityCount),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        maxHeartRate,
        notificationsEnabled,
        userAge,
        exportedFilePath,
        clearedActivityCount,
        errorMessage,
      ];
}