import '../models/heart_rate_device.dart';

abstract class DeviceRepository {
  Future<List<HeartRateDevice>> getPairedDevices();
  Future<void> saveDevice(HeartRateDevice device);
  Future<void> updateDeviceConnection(String id, bool isConnected);
  Future<HeartRateDevice?> getConnectedDevice();
}
