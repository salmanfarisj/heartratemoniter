import '../../../../core/database/database_helper.dart';
import '../../domain/models/activity.dart';
import '../../domain/repositories/activity_repository.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  final DatabaseHelper _databaseHelper;

  ActivityRepositoryImpl(this._databaseHelper);

  @override
  Future<void> saveActivity(Activity activity) async {
    final db = await _databaseHelper.database;
    await db.insert('activities', activity.toMap());
  }

  @override
  Future<List<Activity>> getActivitiesForDate(DateTime date) async {
    final db = await _databaseHelper.database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await db.query(
      'activities',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
      orderBy: 'timestamp DESC',
    );

    return result.map((map) => Activity.fromMap(map)).toList();
  }

  @override
  Future<List<Activity>> getActivitiesInRange(DateTime start, DateTime end) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'activities',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'timestamp DESC',
    );

    return result.map((map) => Activity.fromMap(map)).toList();
  }

  @override
  Future<void> deleteActivity(String id) async {
    final db = await _databaseHelper.database;
    await db.delete('activities', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<int> getTotalCaloriesForDate(DateTime date) async {
    final activities = await getActivitiesForDate(date);
    return activities.fold<int>(0, (sum, a) => sum + (a.calories ?? 0));
  }

  @override
  Future<int> getTotalDurationForDate(DateTime date) async {
    final activities = await getActivitiesForDate(date);
    return activities.fold<int>(0, (sum, a) => sum + a.durationMinutes);
  }

  /// Delete every activity row. Returns the number of rows removed so
  /// callers can confirm the action to the user.
  Future<int> clearAll() async {
    final db = await _databaseHelper.database;
    return db.delete('activities');
  }
}
