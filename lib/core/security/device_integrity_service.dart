import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kReleaseMode;
import 'package:flutter/services.dart';

/// Stub root/jailbreak detection. Real implementations should use
/// platform-specific plugins (e.g. flutter_jailbreak_detection) and
/// runtime integrity checks.
class DeviceIntegrityService {
  const DeviceIntegrityService();

  /// Heuristic check — returns true on iOS Simulator / Android Emulator.
  /// Replace with a real integrity SDK in production.
  Future<bool> isEmulator() async {
    final info = DeviceInfoPlugin();
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = await info.androidInfo;
      return !android.isPhysicalDevice;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = await info.iosInfo;
      return !ios.isPhysicalDevice;
    }
    return false;
  }

  /// Stub — returns false unless [DeviceIntegrityService.isEmulator] is true
  /// and the app is configured to refuse emulator launches.
  Future<bool> isCompromised() async {
    if (kReleaseMode) {
      final emulator = await isEmulator();
      return emulator;
    }
    return false;
  }
}
