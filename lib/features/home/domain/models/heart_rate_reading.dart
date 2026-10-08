import 'package:equatable/equatable.dart';
import 'heart_rate_zone.dart';

class HeartRateReading extends Equatable {
  final String id;
  final int bpm;
  final HeartRateZone zone;
  final DateTime timestamp;
  final String? activityId;

  const HeartRateReading({
    required this.id,
    required this.bpm,
    required this.zone,
    required this.timestamp,
    this.activityId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bpm': bpm,
      'zone': zone.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'activity_id': activityId,
    };
  }

  factory HeartRateReading.fromMap(Map<String, dynamic> map) {
    return HeartRateReading(
      id: map['id'] as String,
      bpm: map['bpm'] as int,
      zone: HeartRateZone.values.firstWhere(
        (z) => z.name == map['zone'],
        orElse: () => HeartRateZone.rest,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      activityId: map['activity_id'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, bpm, zone, timestamp, activityId];
}
