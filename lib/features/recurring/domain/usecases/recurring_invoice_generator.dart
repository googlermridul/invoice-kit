import 'package:invoice_kit/core/constants/invoice_constants.dart';
import 'package:invoice_kit/features/invoices/domain/entities/document.dart'
    show InvoiceStatus;
import 'package:invoice_kit/features/invoices/domain/entities/document_item.dart';
import 'package:invoice_kit/features/invoices/domain/entities/invoice.dart';
import 'package:invoice_kit/features/recurring/domain/entities/recurring_invoice.dart';
import 'package:invoice_kit/shared/helpers/id_generator.dart';

/// Pure-function service that, given a schedule, returns the list of invoices
/// that should be generated. Caps iterations to [InvoiceConstants.maxRecurringCatchup]
/// to avoid runaway loops (e.g. an offline app with years of missed runs).
class RecurringInvoiceGenerator {
  const RecurringInvoiceGenerator._();

  /// Returns the list of (invoice, newNextRunDate) pairs that should be
  /// generated from the schedule between [now] (exclusive of past runs already
  /// fired) and [endBound] (inclusive). The schedule's `nextRunDate` is updated
  /// as a side-effect in [updateNextRunDate].
  static List<Invoice> generate({
    required RecurringInvoice schedule,
    required DateTime now,
    required int invoiceCounter,
    required String invoicePrefix,
    int maxCatchup = InvoiceConstants.maxRecurringCatchup,
  }) {
    if (!schedule.active) return const [];
    final endBound = schedule.endDate ?? now;
    if (endBound.isBefore(schedule.nextRunDate)) return const [];

    final generated = <Invoice>[];
    var next = schedule.nextRunDate;
    var counter = invoiceCounter;

    var safety = 0;
    while (!next.isAfter(endBound) &&
        !next.isAfter(now) &&
        safety < maxCatchup) {
      final items = schedule.items
          .map((json) => DocumentItem.fromJson(json).copyWith())
          .toList();

      final issueDate = next;
      final dueDate = _addDays(issueDate, 14);

      final number = '$invoicePrefix${counter.toString().padLeft(5, '0')}';

      generated.add(
        Invoice(
          id: IdGenerator.create('inv'),
          number: number,
          clientId: schedule.clientId,
          issueDate: issueDate,
          dueDate: dueDate,
          currency: schedule.currency,
          items: items,
          notes: schedule.notes,
          terms: schedule.terms,
          taxRateOverride: schedule.taxRateOverride,
          status: InvoiceStatus.draft,
          recurringId: schedule.id,
        ),
      );

      counter++;
      next = _advance(next, schedule.frequency);
      safety++;
    }

    return generated;
  }

  /// Advance a date by the schedule's frequency.
  static DateTime advance(DateTime date, RecurringFrequency frequency) =>
      _advance(date, frequency);

  static DateTime _advance(DateTime date, RecurringFrequency frequency) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return _addDays(date, 1);
      case RecurringFrequency.weekly:
        return _addDays(date, 7);
      case RecurringFrequency.monthly:
        return _addMonths(date, 1);
      case RecurringFrequency.quarterly:
        return _addMonths(date, 3);
      case RecurringFrequency.yearly:
        return _addMonths(date, 12);
    }
  }

  static DateTime _addDays(DateTime d, int days) {
    final base = DateTime(d.year, d.month, d.day);
    return base.add(Duration(days: days));
  }

  static DateTime _addMonths(DateTime d, int months) {
    final totalMonths = d.month + months;
    final newYear = d.year + ((totalMonths - 1) ~/ 12);
    final newMonth = ((totalMonths - 1) % 12) + 1;
    final lastDayOfMonth = DateTime(newYear, newMonth + 1, 0).day;
    final day = d.day > lastDayOfMonth ? lastDayOfMonth : d.day;
    return DateTime(newYear, newMonth, day);
  }
}
