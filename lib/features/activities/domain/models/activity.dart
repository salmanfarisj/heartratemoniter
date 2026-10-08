import 'package:equatable/equatable.dart';
import 'activity_type.dart';

enum ActivityIntensity { low, medium, high }

class Activity extends Equatable {
  final String id;
  final ActivityType type;
  final String name;
  final int durationMinutes;
  final double? distanceKm;
  final int? calories;
  final int? avgHr;
  final int? maxHr;
  final int? minHr;
  final double? avgPace; // min/km
  final double? elevationGain; // meters
  final int? cadence; // steps/min or rpm
  final double? avgSpeed; // km/h
  final int? zone1Time; // seconds in zone 1 (rest)
  final int? zone2Time; // seconds in zone 2 (fat burn)
  final int? zone3Time; // seconds in zone 3 (cardio)
  final int? zone4Time; // seconds in zone 4 (hard)
  final int? zone5Time; // seconds in zone 5 (max)
  final int? steps;
  final int? floorsClimbed;
  final ActivityIntensity? intensity;
  final int? perceivedExertion; // RPE 1-10
  final String? weather;
  final DateTime timestamp;
  final String? notes;

  const Activity({
    required this.id,
    required this.type,
    required this.name,
    required this.durationMinutes,
    this.distanceKm,
    this.calories,
    this.avgHr,
    this.maxHr,
    this.minHr,
    this.avgPace,
    this.elevationGain,
    this.cadence,
    this.avgSpeed,
    this.zone1Time,
    this.zone2Time,
    this.zone3Time,
    this.zone4Time,
    this.zone5Time,
    this.steps,
    this.floorsClimbed,
    this.intensity,
    this.perceivedExertion,
    this.weather,
    required this.timestamp,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'name': name,
      'duration_minutes': durationMinutes,
      'distance_km': distanceKm,
      'calories': calories,
      'avg_hr': avgHr,
      'max_hr': maxHr,
      'min_hr': minHr,
      'avg_pace': avgPace,
      'elevation_gain': elevationGain,
      'cadence': cadence,
      'avg_speed': avgSpeed,
      'zone1_time': zone1Time,
      'zone2_time': zone2Time,
      'zone3_time': zone3Time,
      'zone4_time': zone4Time,
      'zone5_time': zone5Time,
      'steps': steps,
      'floors_climbed': floorsClimbed,
      'intensity': intensity?.name,
      'perceived_exertion': perceivedExertion,
      'weather': weather,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'notes': notes,
    };
  }

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'] as String,
      type: ActivityType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => ActivityType.other,
      ),
      name: map['name'] as String,
      durationMinutes: map['duration_minutes'] as int,
      distanceKm: map['distance_km'] as double?,
      calories: map['calories'] as int?,
      avgHr: map['avg_hr'] as int?,
      maxHr: map['max_hr'] as int?,
      minHr: map['min_hr'] as int?,
      avgPace: map['avg_pace'] as double?,
      elevationGain: map['elevation_gain'] as double?,
      cadence: map['cadence'] as int?,
      avgSpeed: map['avg_speed'] as double?,
      zone1Time: map['zone1_time'] as int?,
      zone2Time: map['zone2_time'] as int?,
      zone3Time: map['zone3_time'] as int?,
      zone4Time: map['zone4_time'] as int?,
      zone5Time: map['zone5_time'] as int?,
      steps: map['steps'] as int?,
      floorsClimbed: map['floors_climbed'] as int?,
      intensity: map['intensity'] != null
          ? ActivityIntensity.values.firstWhere(
              (i) => i.name == map['intensity'],
              orElse: () => ActivityIntensity.medium,
            )
          : null,
      perceivedExertion: map['perceived_exertion'] as int?,
      weather: map['weather'] as String?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      notes: map['notes'] as String?,
    );
  }

  Activity copyWith({
    String? id,
    ActivityType? type,
    String? name,
    int? durationMinutes,
    double? distanceKm,
    int? calories,
    int? avgHr,
    int? maxHr,
    int? minHr,
    double? avgPace,
    double? elevationGain,
    int? cadence,
    double? avgSpeed,
    int? zone1Time,
    int? zone2Time,
    int? zone3Time,
    int? zone4Time,
    int? zone5Time,
    int? steps,
    int? floorsClimbed,
    ActivityIntensity? intensity,
    int? perceivedExertion,
    String? weather,
    DateTime? timestamp,
    String? notes,
  }) {
    return Activity(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      distanceKm: distanceKm ?? this.distanceKm,
      calories: calories ?? this.calories,
      avgHr: avgHr ?? this.avgHr,
      maxHr: maxHr ?? this.maxHr,
      minHr: minHr ?? this.minHr,
      avgPace: avgPace ?? this.avgPace,
      elevationGain: elevationGain ?? this.elevationGain,
      cadence: cadence ?? this.cadence,
      avgSpeed: avgSpeed ?? this.avgSpeed,
      zone1Time: zone1Time ?? this.zone1Time,
      zone2Time: zone2Time ?? this.zone2Time,
      zone3Time: zone3Time ?? this.zone3Time,
      zone4Time: zone4Time ?? this.zone4Time,
      zone5Time: zone5Time ?? this.zone5Time,
      steps: steps ?? this.steps,
      floorsClimbed: floorsClimbed ?? this.floorsClimbed,
      intensity: intensity ?? this.intensity,
      perceivedExertion: perceivedExertion ?? this.perceivedExertion,
      weather: weather ?? this.weather,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
    );
  }

  int get totalZoneTime =>
      (zone1Time ?? 0) +
      (zone2Time ?? 0) +
      (zone3Time ?? 0) +
      (zone4Time ?? 0) +
      (zone5Time ?? 0);

  String get paceDisplay {
    if (avgPace == null || avgPace == 0) return '--:--';
    final mins = avgPace!.floor();
    final secs = ((avgPace! - mins) * 60).round();
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
        id,
        type,
        name,
        durationMinutes,
        distanceKm,
        calories,
        avgHr,
        maxHr,
        minHr,
        avgPace,
        elevationGain,
        cadence,
        avgSpeed,
        zone1Time,
        zone2Time,
        zone3Time,
        zone4Time,
        zone5Time,
        steps,
        floorsClimbed,
        intensity,
        perceivedExertion,
        weather,
        timestamp,
        notes,
      ];
}
