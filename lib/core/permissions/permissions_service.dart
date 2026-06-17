import 'package:permission_handler/permission_handler.dart';

/// Convenience wrapper around [Permission] for declarative permission flows.
class PermissionsService {
  const PermissionsService();

  Future<PermissionStatus> request(Permission permission) =>
      permission.request();

  Future<PermissionStatus> status(Permission permission) =>
      permission.status;

  Future<bool> isGranted(Permission permission) async =>
      (await permission.status).isGranted;

  Future<void> openSettings() => openAppSettings();
}
