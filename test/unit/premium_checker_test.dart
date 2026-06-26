import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_kit/features/premium/domain/entities/premium_access_decision.dart';
import 'package:invoice_kit/features/premium/domain/services/premium_access_manager.dart';
import 'package:invoice_kit/features/premium/domain/services/premium_checker.dart';
import 'package:invoice_kit/features/premium/domain/services/premium_context.dart';
import 'package:invoice_kit/features/subscription/domain/entities/subscription_status.dart';

void main() {
  group('PremiumChecker', () {
    const checker = PremiumChecker();
    final now = DateTime(2026, 6, 18);

    test('granted for active trial', () {
      final status = SubscriptionStatus(
        state: SubscriptionState.trialing,
        trialStart: now.subtract(const Duration(days: 1)),
        trialEnd: now.add(const Duration(days: 6)),
      );
      final decision = checker.evaluate(
        status: status,
        now: now,
        isAuthenticated: false,
      );
      expect(decision.isGranted, isTrue);
    });

    test('denied for expired trial with no auth', () {
      final status = SubscriptionStatus(
        state: SubscriptionState.expired,
      );
      final decision = checker.evaluate(
        status: status,
        now: now,
        isAuthenticated: false,
      );
      expect(decision.isGranted, isFalse);
      expect(decision.result, PremiumAccessResult.deniedNotAuthenticated);
    });

    test('granted for active subscription', () {
      final status = SubscriptionStatus(
        state: SubscriptionState.active,
        plan: SubscriptionPlan.monthly,
        currentPeriodEnd: now.add(const Duration(days: 14)),
      );
      final decision = checker.evaluate(
        status: status,
        now: now,
        isAuthenticated: true,
      );
      expect(decision.isGranted, isTrue);
    });

    test('denied for expired subscription', () {
      final status = SubscriptionStatus(
        state: SubscriptionState.expired,
        plan: SubscriptionPlan.monthly,
        currentPeriodEnd: now.subtract(const Duration(days: 1)),
      );
      final decision = checker.evaluate(
        status: status,
        now: now,
        isAuthenticated: true,
      );
      expect(decision.isGranted, isFalse);
      expect(decision.result, PremiumAccessResult.deniedExpiredTrial);
    });

    test('cancelled-but-active retains access', () {
      final status = SubscriptionStatus(
        state: SubscriptionState.cancelled,
        currentPeriodEnd: now.add(const Duration(days: 5)),
      );
      final decision = checker.evaluate(
        status: status,
        now: now,
        isAuthenticated: true,
      );
      expect(decision.result, PremiumAccessResult.cancelledButActive);
      expect(decision.isGranted, isTrue);
    });

    test('pending subscription does NOT grant access', () {
      final status = SubscriptionStatus(state: SubscriptionState.pending);
      final decision = checker.evaluate(
        status: status,
        now: now,
        isAuthenticated: true,
      );
      expect(decision.isGranted, isFalse);
    });
  });

  group('PremiumAccessManager', () {
    const manager = PremiumAccessManager(PremiumChecker());
    final now = DateTime(2026, 6, 18);

    test('device limit > max → device management redirect', () {
      final context = PremiumContext(
        status: SubscriptionStatus.initial(),
        isAuthenticated: true,
        deviceCount: 4,
        maxDevices: 3,
        now: now,
      );
      final outcome = manager.resolve(context);
      expect(outcome.redirect, PremiumRedirect.toDeviceManagement);
      expect(outcome.isGranted, isFalse);
    });

    test('expired trial + logged in → subscription redirect', () {
      final context = PremiumContext(
        status: const SubscriptionStatus(state: SubscriptionState.expired),
        isAuthenticated: true,
        deviceCount: 1,
        maxDevices: 3,
        now: now,
      );
      final outcome = manager.resolve(context);
      expect(outcome.redirect, PremiumRedirect.toSubscription);
    });

    test('expired trial + not logged in → auth redirect', () {
      final context = PremiumContext(
        status: const SubscriptionStatus(state: SubscriptionState.expired),
        isAuthenticated: false,
        deviceCount: 0,
        maxDevices: 3,
        now: now,
      );
      final outcome = manager.resolve(context);
      expect(outcome.redirect, PremiumRedirect.toAuth);
    });

    test('active trial → no redirect', () {
      final context = PremiumContext(
        status: SubscriptionStatus(
          state: SubscriptionState.trialing,
          trialStart: now,
          trialEnd: now.add(const Duration(days: 5)),
        ),
        isAuthenticated: false,
        deviceCount: 0,
        maxDevices: 3,
        now: now,
      );
      final outcome = manager.resolve(context);
      expect(outcome.isGranted, isTrue);
      expect(outcome.redirect, PremiumRedirect.none);
    });
  });
}
