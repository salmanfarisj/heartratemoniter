import 'package:equatable/equatable.dart';

class HeartRateStats extends Equatable {
  final int avgHr;
  final int minHr;
  final int maxHr;
  final int readingCount;

  const HeartRateStats({
    required this.avgHr,
    required this.minHr,
    required this.maxHr,
    required this.readingCount,
  });

  const HeartRateStats.empty()
      : avgHr = 0,
        minHr = 0,
        maxHr = 0,
        readingCount = 0;

  /// Build stats from a pre-aggregated SQL row.
  ///
  /// Pass null/zero fields to produce an empty result.
  factory HeartRateStats.fromAggregate({
    required int? minHr,
    required int? maxHr,
    required int? sumBpm,
    required int? count,
  }) {
    if (minHr == null || maxHr == null || count == null || count == 0) {
      return const HeartRateStats.empty();
    }
    final avg = (sumBpm ?? 0) ~/ count;
    return HeartRateStats(
      avgHr: avg,
      minHr: minHr,
      maxHr: maxHr,
      readingCount: count,
    );
  }

  @override
  List<Object?> get props => [avgHr, minHr, maxHr, readingCount];
}