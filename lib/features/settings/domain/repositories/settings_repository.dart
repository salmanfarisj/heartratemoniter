abstract class SettingsRepository {
  /// Maximum physiological cap applied to auto-promoted max-HR updates.
  /// Prevents faulty sensors from locking max to implausible values.
  static const int maxHeartRateCap = 230;

  /// Default age assumed when no age has been stored. Used to compute
  /// the initial default max HR (`220 - age`).
  static const int defaultAge = 30;

  Future<int> getMaxHeartRate();
  Future<void> setMaxHeartRate(int value);
  Future<bool> isMaxHeartRateUserSet();

  /// Persist [value] as the new max HR **without** flipping the
  /// user-set flag. Used by the sustained-heave-auto-promote path so the
  /// next age change can still re-derive max HR.
  Future<void> setMaxHeartRateInternal(int value);

  Future<bool> getNotificationsEnabled();
  Future<void> setNotificationsEnabled(bool value);
  Future<int> getUserAge();
  Future<void> setUserAge(int value);
}