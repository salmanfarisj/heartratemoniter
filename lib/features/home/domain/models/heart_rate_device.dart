import 'package:equatable/equatable.dart';

class HeartRateDevice extends Equatable {
  final String id;
  final String name;
  final String address;
  final int rssi;
  final bool isConnected;
  final DateTime? lastConnected;

  const HeartRateDevice({
    required this.id,
    required this.name,
    required this.address,
    this.rssi = -100,
    this.isConnected = false,
    this.lastConnected,
  });

  HeartRateDevice copyWith({
    String? id,
    String? name,
    String? address,
    int? rssi,
    bool? isConnected,
    DateTime? lastConnected,
  }) {
    return HeartRateDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      rssi: rssi ?? this.rssi,
      isConnected: isConnected ?? this.isConnected,
      lastConnected: lastConnected ?? this.lastConnected,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'is_connected': isConnected ? 1 : 0,
      'last_connected': lastConnected?.millisecondsSinceEpoch,
    };
  }

  factory HeartRateDevice.fromMap(Map<String, dynamic> map) {
    return HeartRateDevice(
      id: map['id'] as String,
      name: map['name'] as String,
      address: map['address'] as String,
      isConnected: (map['is_connected'] as int?) == 1,
      lastConnected: map['last_connected'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_connected'] as int)
          : null,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, address, rssi, isConnected, lastConnected];
}
