import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_kit/core/constants/invoice_constants.dart';
import 'package:invoice_kit/features/subscription/domain/entities/subscription_status.dart';
import 'package:invoice_kit/features/subscription/domain/services/entitlement_service.dart';

void main() {
  group('EntitlementService', () {
    const svc = EntitlementService();
    final now = DateTime(2026, 6, 18);

    group('initial / none state', () {
      test('no access', () {
        final s = SubscriptionStatus.initial();
        expect(svc.hasAccess(s, now), isFalse);
        expect(svc.isBlocked(s, now), isTrue);
        expect(svc.isInTrial(s, now), isFalse);
        expect(svc.trialDaysRemaining(s, now), 0);
        expect(svc.canStartTrial(s), isTrue);
      });
    });

    group('active trial', () {
      test('grants access while within window', () {
        final s = svc.startTrial(SubscriptionStatus.initial(), now);
        expect(svc.hasAccess(s, now), isTrue);
        expect(svc.isInTrial(s, now), isTrue);
        expect(
          svc.trialDaysRemaining(s, now),
          InvoiceConstants.trialDuration.inDays,
        );
      });

      test('trial days remaining counts whole days only', () {
        final started = now.subtract(const Duration(days: 1, hours: 12));
        final s = SubscriptionStatus(
          state: SubscriptionState.trialing,
          trialStart: started,
          trialEnd: started.add(InvoiceConstants.trialDuration),
        );
        expect(svc.isInTrial(s, now), isTrue);
        // 7 day trial, 1.5 days elapsed → 5 whole days remaining
        expect(svc.trialDaysRemaining(s, now), 5);
      });

      test('blocked once trial ends', () {
        final s = SubscriptionStatus(
          state: SubscriptionState.trialing,
          trialStart: now.subtract(const Duration(days: 30)),
          trialEnd: now.subtract(const Duration(seconds: 1)),
        );
        expect(svc.hasAccess(s, now), isFalse);
        expect(svc.isBlocked(s, now), isTrue);
        expect(svc.isInTrial(s, now), isFalse);
      });

      test('canStartTrial is false after a trial was used', () {
        final s = SubscriptionStatus(
          state: SubscriptionState.expired,
          trialStart: now.subtract(const Duration(days: 30)),
          trialEnd: now.subtract(const Duration(days: 16)),
        );
        expect(svc.canStartTrial(s), isFalse);
      });
    });

    group('paid subscription', () {
      test('monthly plan grants access within period', () {
        final s = svc.activate(
          current: SubscriptionStatus.initial(),
          plan: SubscriptionPlan.monthly,
          now: now,
        );
        expect(svc.hasAccess(s, now), isTrue);
        expect(svc.isBlocked(s, now), isFalse);
      });

      test('cancelled plan retains access until period end', () {
        final s = SubscriptionStatus(
          state: SubscriptionState.cancelled,
          plan: SubscriptionPlan.yearly,
          currentPeriodEnd: now.add(const Duration(days: 30)),
        );
        expect(svc.hasAccess(s, now), isTrue);
        expect(svc.isBlocked(s, now), isFalse);
      });

      test('cancelled plan after period end blocks access', () {
        final s = SubscriptionStatus(
          state: SubscriptionState.cancelled,
          plan: SubscriptionPlan.yearly,
          currentPeriodEnd: now.subtract(const Duration(days: 1)),
        );
        expect(svc.hasAccess(s, now), isFalse);
      });

      test('expired plan blocks access', () {
        final s = svc.expire(
          svc.activate(
            current: SubscriptionStatus.initial(),
            plan: SubscriptionPlan.monthly,
            now: now.subtract(const Duration(days: 60)),
          ),
        );
        expect(svc.hasAccess(s, now), isFalse);
        expect(svc.isBlocked(s, now), isTrue);
      });
    });

    test('default monthly period is one calendar month out', () {
      // Jan 15 → Feb 15 (no month-end clamp needed)
      final s = svc.activate(
        current: SubscriptionStatus.initial(),
        plan: SubscriptionPlan.monthly,
        now: DateTime(2026, 1, 15),
      );
      expect(s.currentPeriodEnd, DateTime(2026, 2, 15));
    });

    test('default yearly period is one calendar year out', () {
      final s = svc.activate(
        current: SubscriptionStatus.initial(),
        plan: SubscriptionPlan.yearly,
        now: DateTime(2026, 6, 18),
      );
      expect(s.currentPeriodEnd, DateTime(2027, 6, 18));
    });
  });
}
