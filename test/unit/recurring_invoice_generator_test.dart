import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_kit/features/recurring/domain/entities/recurring_invoice.dart';
import 'package:invoice_kit/features/recurring/domain/usecases/recurring_invoice_generator.dart';

void main() {
  group('RecurringInvoiceGenerator', () {
    final start = DateTime(2026, 1, 1);

    Map<String, dynamic> itemJson() => {
      'id': 'item1',
      'description': 'Subscription',
      'quantity': 1,
      'unitPrice': 100,
      'taxRate': 0,
      'discount': 0,
    };

    RecurringInvoice makeSchedule({
      RecurringFrequency frequency = RecurringFrequency.monthly,
      DateTime? nextRun,
      DateTime? endDate,
      bool active = true,
    }) {
      return RecurringInvoice(
        id: 'rec1',
        clientId: 'c1',
        frequency: frequency,
        startDate: start,
        nextRunDate: nextRun ?? start,
        endDate: endDate,
        currency: 'USD',
        items: [itemJson()],
        active: active,
      );
    }

    test('inactive schedule produces no invoices', () {
      final schedule = makeSchedule(active: false);
      final result = RecurringInvoiceGenerator.generate(
        schedule: schedule,
        now: start.add(const Duration(days: 60)),
        invoiceCounter: 1,
        invoicePrefix: 'INV-',
      );
      expect(result, isEmpty);
    });

    test('single monthly run produces one invoice with correct number', () {
      final schedule = makeSchedule(
        frequency: RecurringFrequency.monthly,
        nextRun: start,
      );
      final result = RecurringInvoiceGenerator.generate(
        schedule: schedule,
        now: start.add(const Duration(days: 5)),
        invoiceCounter: 42,
        invoicePrefix: 'INV-',
      );
      expect(result, hasLength(1));
      expect(result.first.number, 'INV-00042');
      expect(result.first.recurringId, 'rec1');
    });

    test('three months of catchup yields three invoices and advances counter', () {
      final schedule = makeSchedule(
        frequency: RecurringFrequency.monthly,
        nextRun: start,
      );
      final result = RecurringInvoiceGenerator.generate(
        schedule: schedule,
        now: start.add(const Duration(days: 70)),
        invoiceCounter: 1,
        invoicePrefix: 'INV-',
      );
      // Jan 1, Feb 1, Mar 1 → 3 months
      expect(result, hasLength(3));
      expect(result[0].number, 'INV-00001');
      expect(result[1].number, 'INV-00002');
      expect(result[2].number, 'INV-00003');
    });

    test('end date caps catchup', () {
      final schedule = makeSchedule(
        frequency: RecurringFrequency.monthly,
        nextRun: start,
        endDate: start.add(const Duration(days: 35)),
      );
      final result = RecurringInvoiceGenerator.generate(
        schedule: schedule,
        now: start.add(const Duration(days: 365)),
        invoiceCounter: 1,
        invoicePrefix: 'INV-',
      );
      // 35 days covers Jan 1 and Feb 1 only
      expect(result, hasLength(2));
    });

    test('weekly schedule advances by 7 days', () {
      final from = DateTime(2026, 3, 1);
      final next = RecurringInvoiceGenerator.advance(from, RecurringFrequency.weekly);
      expect(next, from.add(const Duration(days: 7)));
    });

    test('yearly schedule advances by 12 months', () {
      final from = DateTime(2026, 1, 31);
      final next = RecurringInvoiceGenerator.advance(from, RecurringFrequency.yearly);
      expect(next.year, 2027);
      expect(next.month, 1);
      expect(next.day, 31);
    });

    test('monthly schedule at end of month clamps day', () {
      final from = DateTime(2026, 1, 31);
      final next = RecurringInvoiceGenerator.advance(from, RecurringFrequency.monthly);
      // Feb has 28 days in 2026
      expect(next.year, 2026);
      expect(next.month, 2);
      expect(next.day, 28);
    });

    test('maxCatchup safety caps iterations', () {
      final schedule = makeSchedule(
        frequency: RecurringFrequency.daily,
        nextRun: start,
      );
      final result = RecurringInvoiceGenerator.generate(
        schedule: schedule,
        now: start.add(const Duration(days: 3650)), // 10 years
        invoiceCounter: 1,
        invoicePrefix: 'INV-',
        maxCatchup: 5,
      );
      expect(result, hasLength(5));
    });

    test('schedule with item json is materialized into DocumentItems', () {
      final schedule = makeSchedule(
        frequency: RecurringFrequency.monthly,
        nextRun: start,
      );
      final result = RecurringInvoiceGenerator.generate(
        schedule: schedule,
        now: start.add(const Duration(days: 1)),
        invoiceCounter: 1,
        invoicePrefix: 'INV-',
      );
      expect(result, hasLength(1));
      expect(result.first.items, isNotEmpty);
      expect(result.first.items.first.description, 'Subscription');
    });
  });
}
