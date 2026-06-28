import 'package:equatable/equatable.dart';

/// Registered device on a Supabase account.
class Device extends Equatable {
  const Device({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.lastSeenAt,
    required this.createdAt,
    this.isCurrent = false,
  });

  factory Device.fromJson(Map<String, dynamic> json) => Device(
    id: json['id']?.toString() ?? '',
    userId: json['user_id']?.toString() ?? '',
    deviceId: json['device_id']?.toString() ?? '',
    deviceName: json['device_name']?.toString() ?? '',
    platform: json['platform']?.toString() ?? 'unknown',
    lastSeenAt:
        DateTime.tryParse(json['last_seen_at']?.toString() ?? '') ??
        DateTime.now(),
    createdAt:
        DateTime.tryParse(json['created_at']?.toString() ?? '') ??
        DateTime.now(),
  );

  final String id;
  final String userId;
  final String deviceId;
  final String deviceName;
  final String platform;
  final DateTime lastSeenAt;
  final DateTime createdAt;

  /// True when this row matches the local device id at runtime.
  final bool isCurrent;

  Device copyWith({
    String? deviceName,
    String? platform,
    DateTime? lastSeenAt,
    bool? isCurrent,
  }) => Device(
    id: id,
    userId: userId,
    deviceId: deviceId,
    deviceName: deviceName ?? this.deviceName,
    platform: platform ?? this.platform,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    createdAt: createdAt,
    isCurrent: isCurrent ?? this.isCurrent,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'device_id': deviceId,
    'device_name': deviceName,
    'platform': platform,
    'last_seen_at': lastSeenAt.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    userId,
    deviceId,
    deviceName,
    platform,
    lastSeenAt,
    createdAt,
    isCurrent,
  ];
}
