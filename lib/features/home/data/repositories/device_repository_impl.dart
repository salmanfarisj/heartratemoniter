import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/models/heart_rate_device.dart';
import '../../domain/repositories/device_repository.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  final DatabaseHelper _databaseHelper;

  DeviceRepositoryImpl(this._databaseHelper);

  @override
  Future<List<HeartRateDevice>> getPairedDevices() async {
    final db = await _databaseHelper.database;
    final result = await db.query('devices', orderBy: 'last_connected DESC');
    return result.map((map) => HeartRateDevice.fromMap(map)).toList();
  }

  @override
  Future<void> saveDevice(HeartRateDevice device) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'devices',
      device.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateDeviceConnection(String id, bool isConnected) async {
    final db = await _databaseHelper.database;
    await db.update(
      'devices',
      {
        'is_connected': isConnected ? 1 : 0,
        'last_connected': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<HeartRateDevice?> getConnectedDevice() async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'devices',
      where: 'is_connected = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return HeartRateDevice.fromMap(result.first);
  }
}
