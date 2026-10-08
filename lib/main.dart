import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/database/database_helper.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/home/data/repositories/heart_rate_repository_impl.dart';
import 'features/home/data/services/heart_rate_bluetooth_service.dart';
import 'features/home/presentation/bloc/heart_rate_bloc.dart';
import 'features/home/presentation/bloc/heart_rate_event.dart';
import 'features/activities/data/repositories/activity_repository_impl.dart';
import 'features/activities/presentation/bloc/activity_bloc.dart';
import 'features/activities/presentation/bloc/activity_event.dart';
import 'features/history/data/repositories/history_repository_impl.dart';
import 'features/history/presentation/bloc/history_bloc.dart';
import 'features/history/presentation/bloc/history_event.dart';
import 'features/settings/data/repositories/settings_repository_impl.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'features/settings/presentation/bloc/settings_event.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final databaseHelper = DatabaseHelper();
  final bluetoothService = BluetoothService();
  final heartRateRepository = HeartRateRepositoryImpl(databaseHelper);
  final activityRepository = ActivityRepositoryImpl(databaseHelper);
  final settingsRepository = SettingsRepositoryImpl(databaseHelper);
  final historyRepository = HistoryRepositoryImpl(
    databaseHelper,
    activityRepository,
  );

  // SettingsBloc is built first so the HeartRateBloc can be wired to
  // dispatch auto-promote events back into it. We construct the bloc
  // eagerly here (then inject via BlocProvider) to get a stable reference
  // for the callback closure.
  final settingsBloc = SettingsBloc(
    repository: settingsRepository,
    heartRateRepository: heartRateRepository,
    activityRepository: activityRepository,
    bluetoothService: bluetoothService,
  )..add(LoadSettings());

  runApp(PulseXApp(
    databaseHelper: databaseHelper,
    bluetoothService: bluetoothService,
    heartRateRepository: heartRateRepository,
    activityRepository: activityRepository,
    settingsRepository: settingsRepository,
    historyRepository: historyRepository,
    settingsBloc: settingsBloc,
  ));
}

class PulseXApp extends StatelessWidget {
  final DatabaseHelper databaseHelper;
  final BluetoothService bluetoothService;
  final HeartRateRepositoryImpl heartRateRepository;
  final ActivityRepositoryImpl activityRepository;
  final SettingsRepositoryImpl settingsRepository;
  final HistoryRepositoryImpl historyRepository;
  final SettingsBloc settingsBloc;

  const PulseXApp({
    super.key,
    required this.databaseHelper,
    required this.bluetoothService,
    required this.heartRateRepository,
    required this.activityRepository,
    required this.settingsRepository,
    required this.historyRepository,
    required this.settingsBloc,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // SettingsBloc is shared across the widget tree so the
        // HeartRateBloc can dispatch auto-promote events into it
        // via the callback wired below.
        BlocProvider<SettingsBloc>.value(value: settingsBloc),
        BlocProvider(
          create: (_) => HeartRateBloc(
            heartRateRepository: heartRateRepository,
            bluetoothService: bluetoothService,
            settingsRepository: settingsRepository,
            onAutoPromoted: (value) =>
                settingsBloc.add(AutoPromoteMaxHeartRate(value)),
          )..add(LoadTodayStats()),
        ),
        BlocProvider(
          create: (context) => ActivityBloc(
            activityRepository: activityRepository,
          )..add(LoadTodayActivities()),
        ),
        BlocProvider(
          create: (context) =>
              HistoryBloc(repository: historyRepository)
                ..add(LoadWeeklyData()),
        ),
      ],
      child: MaterialApp.router(
        title: 'PulseX',
        theme: AppTheme.lightTheme,
        color: AppColors.pulsexBlue,
        darkTheme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}