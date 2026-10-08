import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/repositories/settings_repository.dart';

/// Settings stored in the same SQLite file as the rest of the app, in a
/// `key_value` table. The previous implementation opened a separate
/// `settings.db` file, which meant `Clear All Data` could never wipe
/// settings and a corrupt main DB could leave stale settings behind.
class SettingsRepositoryImpl implements SettingsRepository {
  static const String _tableName = 'key_value';
  static const String _keyMaxHr = 'max_heart_rate';
  static const String _keyMaxHrUserSet = 'max_hr_user_set';
  static const String _keyNotifications = 'notifications_enabled';
  static const String _keyUserAge = 'user_age';

  /// Classic Fox formula. Kept here as the single source of truth so
  /// callers don't have to duplicate the derivation.
  static int deriveMaxHrFromAge(int age) => 220 - age;

  final DatabaseHelper _databaseHelper;

  SettingsRepositoryImpl(this._databaseHelper);

  Future<Database> get _db async => _databaseHelper.database;

  Future<String?> _getValue(String key) async {
    final db = await _db;
    final result = await db.query(
      _tableName,
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }

  Future<void> _setValue(String key, String value) async {
    final db = await _db;
    await db.insert(
      _tableName,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> getMaxHeartRate() async {
    final stored = await _getValue(_keyMaxHr);
    if (stored != null) {
      final parsed = int.tryParse(stored);
      if (parsed != null && parsed > 0) return parsed;
    }
    // No stored max HR — derive from stored age (fallback to default).
    final age = await getUserAge();
    final derived = deriveMaxHrFromAge(age).clamp(100, SettingsRepository.maxHeartRateCap);
    await _setValue(_keyMaxHr, derived.toString());
    await _setValue(_keyMaxHrUserSet, 'false');
    return derived;
  }

  @override
  Future<void> setMaxHeartRate(int value) async {
    await _setValue(_keyMaxHr, value.toString());
    await _setValue(_keyMaxHrUserSet, 'true');
  }

  @override
  Future<bool> isMaxHeartRateUserSet() async {
    final value = await _getValue(_keyMaxHrUserSet);
    return value == 'true';
  }

  @override
  Future<void> setMaxHeartRateInternal(int value) async {
    final capped = value.clamp(100, SettingsRepository.maxHeartRateCap);
    await _setValue(_keyMaxHr, capped.toString());
    // Intentionally do NOT touch _keyMaxHrUserSet — auto-promote keeps the
    // value eligible for age-driven recompute.
  }

  @override
  Future<bool> getNotificationsEnabled() async {
    final value = await _getValue(_keyNotifications);
    return value == 'true';
  }

  @override
  Future<void> setNotificationsEnabled(bool value) async {
    await _setValue(_keyNotifications, value.toString());
  }

  @override
  Future<int> getUserAge() async {
    final value = await _getValue(_keyUserAge);
    return int.tryParse(value ?? SettingsRepository.defaultAge.toString()) ??
        SettingsRepository.defaultAge;
  }

  @override
  Future<void> setUserAge(int value) async {
    await _setValue(_keyUserAge, value.toString());
    final userSet = await isMaxHeartRateUserSet();
    if (!userSet) {
      // No explicit max chosen by the user — keep the derived value in
      // sync with the new age.
      final derived = deriveMaxHrFromAge(value)
          .clamp(100, SettingsRepository.maxHeartRateCap);
      await _setValue(_keyMaxHr, derived.toString());
      await _setValue(_keyMaxHrUserSet, 'false');
    }
  }

  /// Wipe the user-set flag so the next read of [getMaxHeartRate]
  /// re-derives from the (possibly newly-stored) age. Exposed for tests.
  Future<void> resetMaxHeartRateUserSet() async {
    final db = await _db;
    await db.delete(_tableName, where: 'key = ?', whereArgs: [_keyMaxHrUserSet]);
  }
}