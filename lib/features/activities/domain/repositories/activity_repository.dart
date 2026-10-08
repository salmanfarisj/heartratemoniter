import '../models/activity.dart';

abstract class ActivityRepository {
  Future<void> saveActivity(Activity activity);
  Future<List<Activity>> getActivitiesForDate(DateTime date);
  Future<List<Activity>> getActivitiesInRange(DateTime start, DateTime end);
  Future<void> deleteActivity(String id);
  Future<int> getTotalCaloriesForDate(DateTime date);
  Future<int> getTotalDurationForDate(DateTime date);
}
