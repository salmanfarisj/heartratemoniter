import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../../../../core/database/database_helper.dart';
import '../../domain/models/heart_rate_reading.dart';
import '../../domain/models/heart_rate_stats.dart';
import '../../domain/models/heart_rate_zone.dart';
import '../../domain/repositories/heart_rate_repository.dart';

/// SQLite-backed implementation. All aggregation happens in SQL so the
/// Dart side never materializes long row lists.
class HeartRateRepositoryImpl implements HeartRateRepository {
  final DatabaseHelper _databaseHelper;

  HeartRateRepositoryImpl(this._databaseHelper);

  // ---- Single-buffer writes --------------------------------------------------

  /// Append a live reading. The bloc calls this every sample, but the
  /// underlying table is short-lived (auto-pruned) so growth is bounded.
  @override
  Future<void> appendLiveReading(HeartRateReading reading) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'live_hr_readings',
      {
        'timestamp': reading.timestamp.millisecondsSinceEpoch,
        'bpm': reading.bpm,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Drop readings older than [DatabaseHelper.liveBufferSeconds].
  @override
  Future<void> pruneLiveBuffer() async {
    final db = await _databaseHelper.database;
    final cutoff = DateTime.now()
        .subtract(const Duration(seconds: DatabaseHelper.liveBufferSeconds))
        .millisecondsSinceEpoch;
    await db.delete('live_hr_readings', where: 'timestamp < ?', whereArgs: [cutoff]);
  }

  /// Add [bpm] for [second] to today's daily row, and add one second of
  /// dwell-time to the matching zone bucket. Idempotent at the SQL level
  /// via the (day_key) primary key + COALESCE.
  @override
  Future<void> recordAggregated({
    required DateTime second,
    required int bpm,
    required HeartRateZone zone,
  }) async {
    final db = await _databaseHelper.database;
    final key = dayKeyFor(second);
    final ts = second.millisecondsSinceEpoch;
    final zoneColumn = switch (zone) {
      HeartRateZone.rest => 'zone_rest_seconds',
      HeartRateZone.fatBurn => 'zone_fat_burn_seconds',
      HeartRateZone.cardio => 'zone_cardio_seconds',
      HeartRateZone.peak => 'zone_peak_seconds',
    };
    await db.rawInsert(
      '''
      INSERT INTO daily_hr_aggregates
        (day_key, min_bpm, max_bpm, sum_bpm, reading_count,
         zone_rest_seconds, zone_fat_burn_seconds,
         zone_cardio_seconds, zone_peak_seconds, updated_at)
      VALUES (?, ?, ?, ?, 1, 0, 0, 0, 0, ?)
      ON CONFLICT(day_key) DO UPDATE SET
        min_bpm = MIN(min_bpm, excluded.min_bpm),
        max_bpm = MAX(max_bpm, excluded.max_bpm),
        sum_bpm = sum_bpm + excluded.sum_bpm,
        reading_count = reading_count + 1,
        $zoneColumn = $zoneColumn + 1,
        updated_at = excluded.updated_at
      ''',
      [key, bpm, bpm, bpm, ts],
    );
  }

  // ---- Stats queries (SQL aggregates) ----------------------------------

  @override
  Future<HeartRateStats> getStatsForDate(DateTime date) async {
    final db = await _databaseHelper.database;
    final key = dayKeyFor(date);
    final rows = await db.query(
      'daily_hr_aggregates',
      where: 'day_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return const HeartRateStats.empty();
    final row = rows.first;
    return HeartRateStats.fromAggregate(
      minHr: row['min_bpm'] as int?,
      maxHr: row['max_bpm'] as int?,
      sumBpm: row['sum_bpm'] as int?,
      count: row['reading_count'] as int?,
    );
  }

  // ---- Range queries (used by History chart) ----------------------------

  /// Returns the last [days] daily aggregates, oldest-first. Each entry is
  /// already aggregated in SQL.
  Future<List<DailyHrSummary>> getDailySummaries({required int days}) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'daily_hr_aggregates',
      orderBy: 'day_key DESC',
      limit: days,
    );
    // Return oldest-first so callers can render directly into a chart.
    return rows.reversed
        .map(
          (r) => DailyHrSummary(
            dayKey: r['day_key'] as String,
            minHr: r['min_bpm'] as int,
            maxHr: r['max_bpm'] as int,
            avgHr: ((r['sum_bpm'] as int) / (r['reading_count'] as int)).round(),
            readingCount: r['reading_count'] as int,
          ),
        )
        .toList();
  }

  // ---- Bulk delete (used by Settings → Clear All) ----------------------

  @override
  Future<void> clearAll() async {
    final db = await _databaseHelper.database;
    await db.delete('live_hr_readings');
    await db.delete('daily_hr_aggregates');
    await db.delete('heart_rate_readings'); // legacy; safe no-op if absent.
  }

  // ---- Legacy API (kept for any leftover callers, no-op safe) ----------

  @override
  Future<void> saveReading(HeartRateReading reading) =>
      appendLiveReading(reading);

  @override
  Future<List<HeartRateReading>> getReadingsForDate(DateTime date) async {
    final db = await _databaseHelper.database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final result = await db.query(
      'live_hr_readings',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
      orderBy: 'timestamp DESC',
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

  @override
  Future<List<HeartRateReading>> getReadingsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'live_hr_readings',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'timestamp ASC',
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
}

/// Pre-aggregated stats for a single local day.
class DailyHrSummary {
  final String dayKey;
  final int minHr;
  final int maxHr;
  final int avgHr;
  final int readingCount;

  const DailyHrSummary({
    required this.dayKey,
    required this.minHr,
    required this.maxHr,
    required this.avgHr,
    required this.readingCount,
  });
}