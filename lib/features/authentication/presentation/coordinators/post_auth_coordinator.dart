import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_kit/app/app_config.dart';
import 'package:invoice_kit/core/di/injection.dart';
import 'package:invoice_kit/core/logger/logger.dart';
import 'package:invoice_kit/core/router/route_paths.dart';
import 'package:invoice_kit/features/authentication/domain/entities/user.dart';
import 'package:invoice_kit/features/devices/domain/usecases/enforce_device_limit_usecase.dart';
import 'package:invoice_kit/features/devices/domain/usecases/register_device_usecase.dart';
import 'package:invoice_kit/features/premium/domain/services/premium_access_manager.dart';
import 'package:invoice_kit/features/premium/domain/services/premium_context.dart';
import 'package:invoice_kit/features/premium/presentation/bloc/premium_cubit.dart';
import 'package:invoice_kit/features/subscription/data/repositories/subscription_repository.dart';
import 'package:invoice_kit/features/subscription/presentation/bloc/subscription_bloc.dart';

/// Outcome of [PostAuthCoordinator.run] — captures the route the user
/// should land on after authentication, plus the reason. Used both by
/// unit tests and by the auth screens themselves.
enum PostAuthRoute { dashboard, devices, subscription }

class PostAuthResult {
  const PostAuthResult({
    required this.route,
    required this.reason,
  });

  final PostAuthRoute route;
  final String reason;

  String get path => switch (route) {
    PostAuthRoute.dashboard => RoutePaths.dashboard,
    PostAuthRoute.devices => RoutePaths.devices,
    PostAuthRoute.subscription => RoutePaths.subscription,
  };

  @override
  String toString() => 'PostAuthResult(route=$route, reason=$reason)';
}

/// Drives the post-authentication pipeline:
///
///   1. Register the current device on the backend (Supabase `devices`).
///   2. Enforce the device limit. If exceeded → redirect to `/devices`.
///   3. Refresh the subscription from the backend so premium state is up
///      to date for the just-authenticated user.
///   4. Refresh the `PremiumCubit` so the rest of the app sees the new
///      decision and route guard runs again.
///   5. Pick the destination:
///         - device limit exceeded → `/devices`
///         - active subscription   → `/dashboard`
///         - otherwise             → `/subscription`
///
/// The coordinator is intentionally `BuildContext`-free so it can be
/// unit-tested without Flutter. The screen calls [navigate] with the
/// returned [PostAuthResult] to perform the actual navigation.
class PostAuthCoordinator {
  PostAuthCoordinator({
    RegisterDeviceUseCase? registerDevice,
    EnforceDeviceLimitUseCase? enforceDeviceLimit,
    SubscriptionRepository? subscriptionRepository,
    PremiumAccessManager? premiumManager,
    SubscriptionBloc? subscriptionBloc,
    PremiumCubit? premiumCubit,
    AppConfig? config,
    CoreLogger? logger,
  }) : _registerDevice = registerDevice ?? sl<RegisterDeviceUseCase>(),
       _enforceDeviceLimit =
           enforceDeviceLimit ?? sl<EnforceDeviceLimitUseCase>(),
       _subscriptionRepository =
           subscriptionRepository ?? sl<SubscriptionRepository>(),
       _manager = premiumManager ?? sl<PremiumAccessManager>(),
       _subscriptionBloc = subscriptionBloc,
       _premiumCubit = premiumCubit,
       _config = config ?? sl<AppConfig>(),
       _logger = logger ?? sl<CoreLogger>();

  final RegisterDeviceUseCase _registerDevice;
  final EnforceDeviceLimitUseCase _enforceDeviceLimit;
  final SubscriptionRepository _subscriptionRepository;
  final PremiumAccessManager _manager;
  final SubscriptionBloc? _subscriptionBloc;
  final PremiumCubit? _premiumCubit;
  final AppConfig _config;
  final CoreLogger _logger;

  /// Pure decision — given the freshly authenticated [user], run the
  /// pipeline and return the route + reason. Does not touch `GoRouter`.
  Future<PostAuthResult> run({
    required User user,
    required String deviceId,
    required String deviceName,
    required String platform,
    DateTime? now,
  }) async {
    // 1. Register the current device.
    try {
      await _registerDevice(
        userId: user.id,
        deviceId: deviceId,
        deviceName: deviceName,
        platform: platform,
      );
    } on Object catch (e, st) {
      _logger.raw.w('PostAuth: device registration failed: $e\n$st');
    }

    // 2. Device-limit gate.
    final withinLimit = await _enforceDeviceLimit(
      userId: user.id,
      maxDevices: _config.maxDevicesPerAccount,
    );
    if (!withinLimit) {
      return const PostAuthResult(
        route: PostAuthRoute.devices,
        reason: 'device-limit-exceeded',
      );
    }

    // 3. Subscription refresh.
    final status = await _subscriptionRepository.refresh();
    final evaluated = now ?? DateTime.now();
    final hasAccess = status.hasAccess(evaluated);

    // 4. Notify blocs / cubits so the rest of the app re-evaluates.
    _subscriptionBloc?.add(const SubscriptionStarted());
    await _premiumCubit?.refresh();

    // 5. Resolve the destination.
    if (hasAccess) {
      return const PostAuthResult(
        route: PostAuthRoute.dashboard,
        reason: 'active-subscription',
      );
    }

    final outcome = _manager.resolve(
      PremiumContext(
        status: status,
        isAuthenticated: true,
        deviceCount: 0, // already verified within limit above
        maxDevices: _config.maxDevicesPerAccount,
        now: evaluated,
      ),
    );
    if (outcome.redirect == PremiumRedirect.toDeviceManagement) {
      return const PostAuthResult(
        route: PostAuthRoute.devices,
        reason: 'premium-device-management',
      );
    }

    return const PostAuthResult(
      route: PostAuthRoute.subscription,
      reason: 'no-active-subscription',
    );
  }

  /// Convenience: run + navigate using the supplied [router]. No-op
  /// outside `mounted` windows.
  Future<PostAuthResult> navigate(
    GoRouter router, {
    required User user,
    required String deviceId,
    required String deviceName,
    required String platform,
    DateTime? now,
  }) async {
    final result = await run(
      user: user,
      deviceId: deviceId,
      deviceName: deviceName,
      platform: platform,
      now: now,
    );
    if (kDebugMode) {
      _logger.raw.d('PostAuth -> ${result.path} (reason=${result.reason})');
    }
    router.go(result.path);
    return result;
  }
}
