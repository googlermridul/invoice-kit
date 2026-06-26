import 'dart:async';

import 'package:invoice_kit/core/constants/storage_keys.dart';
import 'package:invoice_kit/core/errors/error_handler.dart';
import 'package:invoice_kit/core/errors/failures.dart';
import 'package:invoice_kit/core/storage/secure_storage_service.dart';
import 'package:invoice_kit/features/devices/domain/entities/device.dart';
import 'package:invoice_kit/features/devices/domain/repositories/device_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  DeviceRepositoryImpl({
    required this._client,
    required this._secure,
    required this._errorHandler,
  });

  final SupabaseClient _client;
  final SecureStorageService _secure;
  final ErrorHandler _errorHandler;

  Future<List<Device>> _listFor(
    String userId, {
    String? currentDeviceId,
  }) async {
    return _errorHandler.guard(() async {
      final rows = await _client
          .from(SupabaseTables.devices)
          .select()
          .eq('user_id', userId)
          .order('last_seen_at', ascending: false);
      final list = (rows as List<dynamic>? ?? const [])
          .map((e) => Device.fromJson(Map<String, dynamic>.from(e as Map)))
          .map(
            (d) => d.copyWith(
              isCurrent:
                  currentDeviceId != null && d.deviceId == currentDeviceId,
            ),
          )
          .toList();
      return list;
    });
  }

  @override
  Future<List<Device>> fetchDevices({required String userId}) async {
    final id = await currentDeviceId();
    return _listFor(userId, currentDeviceId: id);
  }

  @override
  Future<Device> registerDevice({
    required String userId,
    required String deviceId,
    required String deviceName,
    required String platform,
  }) async {
    return _errorHandler.guard(() async {
      await _client.from(SupabaseTables.devices).upsert(
        {
          'user_id': userId,
          'device_id': deviceId,
          'device_name': deviceName,
          'platform': platform,
          'last_seen_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,device_id',
      );
      final rows = await _client
          .from(SupabaseTables.devices)
          .select()
          .eq('user_id', userId)
          .eq('device_id', deviceId)
          .limit(1);
      if (rows.isEmpty) {
        throw const DeviceLimitFailure(message: 'Device registration failed.');
      }
      return Device.fromJson(
        Map<String, dynamic>.from(rows.first as Map),
      ).copyWith(isCurrent: true);
    });
  }

  @override
  Future<void> removeDevice({required String deviceId}) async {
    return _errorHandler.guard(() async {
      await _client
          .from(SupabaseTables.devices)
          .delete()
          .eq('device_id', deviceId);
    });
  }

  @override
  Future<bool> enforceDeviceLimit({
    required String userId,
    required int maxDevices,
  }) async {
    final id = await currentDeviceId();
    final list = await _listFor(userId, currentDeviceId: id);
    return list.length <= maxDevices;
  }

  @override
  Future<String> currentDeviceId() async {
    final existing = await _secure.read(SecureKeys.deviceId);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    await _secure.write(SecureKeys.deviceId, id);
    return id;
  }

  @override
  Future<void> setCurrentDeviceId(String deviceId) =>
      _secure.write(SecureKeys.deviceId, deviceId);
}
