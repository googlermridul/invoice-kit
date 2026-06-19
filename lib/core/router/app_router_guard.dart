import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_kit/core/constants/storage_keys.dart';
import 'package:invoice_kit/core/di/injection.dart';
import 'package:invoice_kit/core/router/route_paths.dart';
import 'package:invoice_kit/core/storage/local_storage_service.dart';
import 'package:invoice_kit/features/subscription/data/repositories/subscription_repository.dart';
import 'package:invoice_kit/features/subscription/domain/services/entitlement_service.dart';
import 'package:invoice_kit/features/subscription/presentation/bloc/subscription_bloc.dart';

/// Decides where to redirect the user based on the current state of:
///  - onboarding completion
///  - subscription / trial entitlement
class AppRouterGuard {
  AppRouterGuard({
    required this.subscriptionBloc,
    LocalStorageService? localStorage,
    SubscriptionRepository? subscriptionRepo,
    EntitlementService? entitlements,
  }) : localStorage = localStorage ?? sl<LocalStorageService>(),
       subscriptionRepo = subscriptionRepo ?? sl<SubscriptionRepository>(),
       entitlements = entitlements ?? sl<EntitlementService>();

  final SubscriptionBloc subscriptionBloc;
  final LocalStorageService localStorage;
  final SubscriptionRepository subscriptionRepo;
  final EntitlementService entitlements;

  String? redirect(BuildContext context, GoRouterState state) {
    final completed = localStorage.getBool(StorageKeys.onboardingCompleted) ?? false;
    if (!completed) {
      // Allow only the splash and onboarding routes.
      final allowed = {
        RoutePaths.splash,
        RoutePaths.onboarding,
      };
      return allowed.contains(state.matchedLocation) ? null : RoutePaths.onboarding;
    }

    final subState = subscriptionBloc.state;
    final hasAccess = subState.hasAccess;
    if (!hasAccess) {
      final allowed = {
        RoutePaths.splash,
        RoutePaths.subscription,
      };
      return allowed.contains(state.matchedLocation) ? null : RoutePaths.subscription;
    }

    return null;
  }
}
