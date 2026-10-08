import '../models/heart_rate_reading.dart';
import '../models/heart_rate_stats.dart';
import '../models/heart_rate_zone.dart';

abstract class HeartRateRepository {
  /// Append a sample to the live, prunable buffer.
  Future<void> appendLiveReading(HeartRateReading reading);

  /// Drop samples older than the live-buffer window.
  Future<void> pruneLiveBuffer();

  /// Update today's daily aggregate with one second of [bpm] in [zone].
  /// Implementation idempotently upserts the row keyed by local day.
  Future<void> recordAggregated({
    required DateTime second,
    required int bpm,
    required HeartRateZone zone,
  });

  /// Get pre-computed stats for the local day of [date].
  Future<HeartRateStats> getStatsForDate(DateTime date);

  /// Clear all stored heart-rate data (live + aggregates).
  Future<void> clearAll();

  // ---- Legacy API kept for any leftover imports; safe no-ops ----------
  Future<void> saveReading(HeartRateReading reading);
  Future<List<HeartRateReading>> getReadingsForDate(DateTime date);
  Future<List<HeartRateReading>> getReadingsInRange(DateTime start, DateTime end);
}