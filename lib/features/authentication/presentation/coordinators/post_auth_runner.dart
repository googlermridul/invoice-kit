import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_kit/core/di/injection.dart';
import 'package:invoice_kit/features/authentication/domain/entities/user.dart';
import 'package:invoice_kit/features/authentication/presentation/bloc/auth_bloc.dart' show AuthState;
import 'package:invoice_kit/features/authentication/presentation/coordinators/post_auth_coordinator.dart';
import 'package:invoice_kit/features/devices/domain/repositories/device_repository.dart';

/// Bridges a successful [AuthState] to the [PostAuthCoordinator].
///
/// Screens call [PostAuthRunner.run] from their `BlocListener` when
/// `state.status == AuthStatus.authenticated`. The runner resolves the
/// current device ID, builds a device label, then delegates to the
/// coordinator which performs device registration, subscription sync,
/// and routing.
class PostAuthRunner {
  PostAuthRunner._();

  /// Resolvable seam for unit tests. Falls back to GetIt in production.
  static PostAuthCoordinator Function() _factory = PostAuthCoordinator.new;

  /// Override the factory (used by tests to inject fakes).
  @visibleForTesting
  static void overrideFactory(PostAuthCoordinator Function() factory) {
    _factory = factory;
  }

  /// Run the post-auth pipeline. Returns the [PostAuthResult] the
  /// coordinator chose. Errors during the device / subscription phase
  /// are swallowed by the coordinator and routed to `/subscription`
  /// (the safest non-blocking destination for a logged-in user without
  /// a confirmed subscription).
  static Future<PostAuthResult> run({
    required BuildContext context,
    required GoRouter router,
    required User user,
  }) async {
    final coordinator = _factory();
    final devices = sl<DeviceRepository>();
    final deviceId = await devices.currentDeviceId();
    final platform = _platform();
    final deviceName = _deviceName(platform);

    return coordinator.navigate(
      router,
      user: user,
      deviceId: deviceId,
      deviceName: deviceName,
      platform: platform,
    );
  }

  static String _platform() {
    if (kIsWeb) return 'web';
    try {
      return Platform.operatingSystem;
    } on Object {
      return defaultTargetPlatform.name;
    }
  }

  static String _deviceName(String platform) {
    if (kIsWeb) {
      return 'Web · ${defaultTargetPlatform.name}';
    }
    try {
      return '${Platform.operatingSystem} · ${Platform.operatingSystemVersion}';
    } on Object {
      return platform;
    }
  }
}
