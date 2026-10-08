import '../../../../core/database/database_helper.dart';
import '../../../home/domain/models/heart_rate_reading.dart';
import '../../../home/domain/models/heart_rate_zone.dart';
import '../../../activities/domain/models/activity.dart';
import '../../../activities/data/repositories/activity_repository_impl.dart';
import '../models/hr_trend.dart';
import '../models/weekly_hr_data.dart';

/// History data layer. Reads from the same SQLite file used by the rest of
/// the app (pulsex.db), keeping settings + HR + activities in
/// one place.
class HistoryRepositoryImpl {
  final DatabaseHelper _databaseHelper;
  final ActivityRepositoryImpl _activities;

  HistoryRepositoryImpl(this._databaseHelper, this._activities);

  /// Aggregate the last [count] days of HR data into a [WeeklyHrData]
  /// suitable for the line chart. Days with no data are zero-filled so
  /// the chart's X axis is contiguous.
  Future<WeeklyHrData> getWeeklyHrData({int days = 7}) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'daily_hr_aggregates',
      orderBy: 'day_key DESC',
      limit: days,
    );
    // Index by day_key for O(1) lookup during fill.
    final byKey = <String, Map<String, Object?>>{
      for (final r in rows) r['day_key'] as String: r,
    };
    final dailyAvg = <int>[];
    final dailyMax = <int>[];
    final dailyMin = <int>[];
    final dayLabels = <String>[];
    final today = DateTime.now();
    // Walk backwards `days` days so output is oldest-first.
    for (int offset = days - 1; offset >= 0; offset--) {
      final d = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: offset));
      final key = dayKeyFor(d);
      final row = byKey[key];
      if (row == null) {
        dailyAvg.add(0);
        dailyMax.add(0);
        dailyMin.add(0);
      } else {
        final sum = row['sum_bpm'] as int;
        final count = row['reading_count'] as int;
        dailyAvg.add(count == 0 ? 0 : (sum ~/ count));
        dailyMax.add(row['max_bpm'] as int);
        dailyMin.add(row['min_bpm'] as int);
      }
      const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      dayLabels.add(labels[(d.weekday - 1) % 7]);
    }
    return WeeklyHrData(
      dailyAvg: dailyAvg,
      dailyMax: dailyMax,
      dailyMin: dailyMin,
      dayLabels: dayLabels,
    );
  }

  /// Most recent raw HR samples in the live buffer. Used to populate the
  /// "Recent Heart Rate" list at the bottom of the history page.
  Future<List<HeartRateReading>> getHrReadingsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'live_hr_readings',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'timestamp DESC',
      limit: 50,
    );
    return result
        .map(
          (m) => HeartRateReading(
            id: '${m['timestamp']}',
            bpm: m['bpm'] as int,
            zone: HeartRateZone.rest,
            timestamp: DateTime.fromMillisecondsSinceEpoch(m['timestamp'] as int),
          ),
        )
        .toList();
  }

  /// Activities in the given window, ordered newest-first.
  Future<List<Activity>> getActivitiesInRange(
    DateTime start,
    DateTime end,
  ) async {
    return _activities.getActivitiesInRange(start, end);
  }

  /// Today's dense HR time-series (one entry per `live_hr_readings`
  /// row), plus the sum of `distance_km` across today's activities.
  /// Used to render the Wahoo-style red filled HR-trend chart on the
  /// History screen.
  Future<HrTrend> getTodayHrTrend({DateTime? now}) async {
    final today = now ?? DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final db = await _databaseHelper.database;
    final rows = await db.query(
      'live_hr_readings',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
      orderBy: 'timestamp ASC',
    );

    final samples = <HrTrendSample>[
      for (final r in rows)
        HrTrendSample(
          timestamp: DateTime.fromMillisecondsSinceEpoch(r['timestamp'] as int),
          bpm: r['bpm'] as int,
        ),
    ];

    final todayActivities = await _activities.getActivitiesInRange(
      startOfDay,
      endOfDay,
    );
    final distanceKm = todayActivities.fold<double>(
      0,
      (sum, a) => sum + (a.distanceKm ?? 0),
    );

    return HrTrend(samples: samples, distanceKm: distanceKm);
  }
}