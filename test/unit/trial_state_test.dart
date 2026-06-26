import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_kit/core/constants/invoice_constants.dart';
import 'package:invoice_kit/features/trial/domain/entities/trial_state.dart';

void main() {
  group('TrialState', () {
    final now = DateTime(2026, 6, 18);

    test('starts active for 7 days by default', () {
      final t = TrialState.fresh(now);
      expect(t.isActive(now), isTrue);
      expect(
        t.daysRemaining(now),
        InvoiceConstants.trialDuration.inDays,
      );
      expect(InvoiceConstants.trialDuration.inDays, 7);
    });

    test('expires exactly after 7 days', () {
      final t = TrialState.fresh(now);
      final later = now.add(const Duration(days: 7, seconds: 1));
      expect(t.isActive(later), isFalse);
      expect(t.daysRemaining(later), 0);
    });

    test('days remaining counts whole days only', () {
      final t = TrialState.fresh(now);
      final afterOneDay = now.add(const Duration(days: 1, hours: 12));
      // Started at midnight Jun 18; trial ends at midnight Jun 25.
      // At noon Jun 19 there are 6 whole days remaining.
      expect(t.daysRemaining(afterOneDay), 6);
    });

    test('manual markExpired terminates access', () {
      final t = TrialState.fresh(now).markExpired();
      expect(t.isActive(now), isFalse);
      expect(t.expired, isTrue);
    });

    test('round trips through json', () {
      final t = TrialState.fresh(now);
      final copy = TrialState.fromJson(t.toJson());
      expect(copy, equals(t));
    });
  });
}
