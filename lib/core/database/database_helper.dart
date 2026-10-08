import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Single SQLite database backing every feature in the app.
///
/// Schema version 3:
/// - `live_hr_readings` is a small, append-only buffer for raw samples.
///   Old rows are pruned on every flush (anything older than [liveBufferSeconds]).
/// - `daily_hr_aggregates` keeps per-day min/avg/max/count/zone-buckets;
///   stats queries hit this table instead of materializing rows in Dart.
/// - `activities` keeps logged activities (unchanged from v1+v2 migration).
/// - `devices` keeps paired HR devices (unchanged).
/// - `key_value` keeps app settings (new in v3, replaces the old
///   `settings.db` file).
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  /// Seconds of raw samples to retain before pruning. One hour is enough
  /// for the live chart and matches typical HR-strapp session duration.
  static const int liveBufferSeconds = 3600;

  Future<Database> get database async {
    final cached = _database;
    if (cached != null) return cached;
    final fresh = await _initDatabase();
    _database = fresh;
    return fresh;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pulsex.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Live, prunable ring of raw samples.
    await db.execute('''
      CREATE TABLE live_hr_readings (
        timestamp INTEGER PRIMARY KEY NOT NULL,
        bpm INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_live_hr_readings_ts ON live_hr_readings(timestamp)',
    );

    // Per-day aggregates. Stats queries hit this table only.
    await db.execute('''
      CREATE TABLE daily_hr_aggregates (
        day_key TEXT PRIMARY KEY NOT NULL,
        min_bpm INTEGER NOT NULL,
        max_bpm INTEGER NOT NULL,
        sum_bpm INTEGER NOT NULL,
        reading_count INTEGER NOT NULL,
        zone_rest_seconds INTEGER NOT NULL DEFAULT 0,
        zone_fat_burn_seconds INTEGER NOT NULL DEFAULT 0,
        zone_cardio_seconds INTEGER NOT NULL DEFAULT 0,
        zone_peak_seconds INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Activities (mirrors the original schema; v1 created it on its own).
    await db.execute('''
      CREATE TABLE activities (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        name TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        distance_km REAL,
        calories INTEGER,
        avg_hr INTEGER,
        max_hr INTEGER,
        min_hr INTEGER,
        avg_pace REAL,
        elevation_gain REAL,
        cadence INTEGER,
        avg_speed REAL,
        zone1_time INTEGER,
        zone2_time INTEGER,
        zone3_time INTEGER,
        zone4_time INTEGER,
        zone5_time INTEGER,
        steps INTEGER,
        floors_climbed INTEGER,
        intensity TEXT,
        perceived_exertion INTEGER,
        weather TEXT,
        timestamp INTEGER NOT NULL,
        notes TEXT
      )
    ''');

    // Paired HR devices.
    await db.execute('''
      CREATE TABLE devices (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        is_connected INTEGER DEFAULT 0,
        last_connected INTEGER
      )
    ''');

    // Key/value settings (replaces the old settings.db).
    await db.execute('''
      CREATE TABLE key_value (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // Seed settings defaults.
    await db.insert('key_value', {'key': 'max_heart_rate', 'value': '180'});
    await db.insert('key_value', {'key': 'notifications_enabled', 'value': 'true'});
    await db.insert('key_value', {'key': 'user_age', 'value': '30'});
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v1 -> v2: extended activities columns. Kept identical to the
      // pre-refactor _onUpgrade so existing installs upgrade cleanly.
      await db.execute('ALTER TABLE activities ADD COLUMN avg_pace REAL');
      await db.execute('ALTER TABLE activities ADD COLUMN elevation_gain REAL');
      await db.execute('ALTER TABLE activities ADD COLUMN cadence INTEGER');
      await db.execute('ALTER TABLE activities ADD COLUMN avg_speed REAL');
      await db.execute('ALTER TABLE activities ADD COLUMN zone1_time INTEGER');
      await db.execute('ALTER TABLE activities ADD COLUMN zone2_time INTEGER');
      await db.execute('ALTER TABLE activities ADD COLUMN zone3_time INTEGER');
      await db.execute('ALTER TABLE activities ADD COLUMN zone4_time INTEGER');
      await db.execute('ALTER TABLE activities ADD COLUMN zone5_time INTEGER');
      await db.execute('ALTER TABLE activities ADD COLUMN steps INTEGER');
      await db.execute('ALTER TABLE activities ADD COLUMN floors_climbed INTEGER');
      await db.execute('ALTER TABLE activities ADD COLUMN intensity TEXT');
      await db.execute('ALTER TABLE activities ADD COLUMN perceived_exertion INTEGER');
      await db.execute('ALTER TABLE activities ADD COLUMN weather TEXT');
    }
    if (oldVersion < 3) {
      // v2 -> v3: replace heart_rate_readings with the live+aggregate
      // schema. Old rows are dropped because the live buffer is meant to
      // be ephemeral and the per-day aggregate has been computed
      // incrementally since v1.
      await db.execute('DROP TABLE IF EXISTS heart_rate_readings');
      await db.execute('''
        CREATE TABLE live_hr_readings (
          timestamp INTEGER PRIMARY KEY NOT NULL,
          bpm INTEGER NOT NULL
        )
      ''');
      await db.execute(
        'CREATE INDEX idx_live_hr_readings_ts ON live_hr_readings(timestamp)',
      );
      await db.execute('''
        CREATE TABLE daily_hr_aggregates (
          day_key TEXT PRIMARY KEY NOT NULL,
          min_bpm INTEGER NOT NULL,
          max_bpm INTEGER NOT NULL,
          sum_bpm INTEGER NOT NULL,
          reading_count INTEGER NOT NULL,
          zone_rest_seconds INTEGER NOT NULL DEFAULT 0,
          zone_fat_burn_seconds INTEGER NOT NULL DEFAULT 0,
          zone_cardio_seconds INTEGER NOT NULL DEFAULT 0,
          zone_peak_seconds INTEGER NOT NULL DEFAULT 0,
          updated_at INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE key_value (
          key TEXT PRIMARY KEY,
          value TEXT
        )
      ''');
      await db.insert('key_value', {'key': 'max_heart_rate', 'value': '180'});
      await db.insert('key_value', {'key': 'notifications_enabled', 'value': 'true'});
      await db.insert('key_value', {'key': 'user_age', 'value': '30'});
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

/// "YYYY-MM-DD" key for a local-day aggregate. Kept in one place so the
/// bloc and the repository agree on day boundaries.
String dayKeyFor(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}