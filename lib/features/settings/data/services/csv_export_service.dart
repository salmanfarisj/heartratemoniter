import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../home/domain/models/heart_rate_reading.dart';
import '../../../activities/domain/models/activity.dart';

/// Builds CSV exports for HR samples and Activities, then hands them off
/// to the system share sheet. `share_plus` is already a project
/// dependency; previously the export service wrote the file to documents
/// and returned a path that nothing consumed.
class CsvExportService {
  /// Returns the path of the written file on success, or `null` if the
  /// user cancelled the share sheet or no platform share handler exists.
  Future<String?> exportHeartRateData(List<HeartRateReading> readings) async {
    final csv = _buildHrCsv(readings);
    final path = await _writeToFile('heart_rate_export.csv', csv);
    await _shareFile(path);
    return path;
  }

  Future<String?> exportActivitiesData(List<Activity> activities) async {
    final csv = _buildActivitiesCsv(activities);
    final path = await _writeToFile('activities_export.csv', csv);
    await _shareFile(path);
    return path;
  }

  String _buildHrCsv(List<HeartRateReading> readings) {
    final buffer = StringBuffer();
    buffer.writeln('ID,BPM,Zone,Timestamp,Activity ID');
    for (final r in readings) {
      buffer.writeln([
        _escape(r.id),
        r.bpm,
        _escape(r.zone.name),
        _escape(r.timestamp.toIso8601String()),
        _escape(r.activityId ?? ''),
      ].join(','));
    }
    return buffer.toString();
  }

  String _buildActivitiesCsv(List<Activity> activities) {
    final buffer = StringBuffer();
    buffer.writeln(
      'ID,Type,Name,Duration (min),Distance (km),Calories,Avg HR,Max HR,Min HR,Timestamp,Notes',
    );
    for (final a in activities) {
      buffer.writeln([
        _escape(a.id),
        _escape(a.type.name),
        _escape(a.name),
        a.durationMinutes,
        a.distanceKm ?? '',
        a.calories ?? '',
        a.avgHr ?? '',
        a.maxHr ?? '',
        a.minHr ?? '',
        _escape(a.timestamp.toIso8601String()),
        _escape(a.notes ?? ''),
      ].join(','));
    }
    return buffer.toString();
  }

  Future<String> _writeToFile(String filename, String content) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsString(content);
    return file.path;
  }

  Future<void> _shareFile(String path) async {
    await Share.shareXFiles(
      [XFile(path)],
      subject: 'Heart rate data export',
    );
  }

  /// Quote and escape a field for CSV. Handles commas, quotes, and
  /// embedded newlines (notes).
  String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      final escaped = value.replaceAll('"', '""');
      return '"$escaped"';
    }
    return value;
  }
}