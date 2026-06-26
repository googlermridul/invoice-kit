import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_kit/core/router/route_paths.dart';
import 'package:invoice_kit/features/premium/domain/services/premium_access_manager.dart';
import 'package:invoice_kit/features/premium/domain/services/premium_checker.dart';
import 'package:invoice_kit/features/premium/domain/services/premium_context.dart';
import 'package:invoice_kit/features/premium/domain/services/premium_route_guard.dart';
import 'package:invoice_kit/features/subscription/domain/entities/subscription_status.dart';

void main() {
  group('PremiumRouteGuard', () {
    const guard = PremiumRouteGuard(PremiumAccessManager(PremiumChecker()));
    final now = DateTime(2026, 6, 18);

    PremiumContext grantedContext() => PremiumContext(
      status: SubscriptionStatus(
        state: SubscriptionState.trialing,
        trialEnd: now.add(const Duration(days: 7)),
      ),
      isAuthenticated: false,
      deviceCount: 0,
      maxDevices: 3,
      now: now,
    );

    PremiumContext deniedContext() => PremiumContext(
      status: const SubscriptionStatus(state: SubscriptionState.expired),
      isAuthenticated: false,
      deviceCount: 0,
      maxDevices: 3,
      now: now,
    );

    test('non-premium route is always allowed', () {
      expect(guard.protect(grantedContext(), RoutePaths.dashboard), isNull);
      expect(guard.protect(deniedContext(), RoutePaths.dashboard), isNull);
    });

    test('premium route allowed for active trial', () {
      expect(guard.protect(grantedContext(), RoutePaths.reports), isNull);
    });

    test('premium route blocked for expired trial → login redirect', () {
      final target = guard.protect(deniedContext(), RoutePaths.reports);
      expect(target, RoutePaths.login);
    });

    test('invoice editor route blocked for expired trial', () {
      final target = guard.protect(deniedContext(), RoutePaths.invoiceNew);
      expect(target, RoutePaths.login);
    });

    test('evaluate returns expected decision enum', () {
      final decision = guard.evaluate(deniedContext(), RoutePaths.reports);
      expect(decision, PremiumRouteDecision.redirectToAuth);
    });
  });
}
