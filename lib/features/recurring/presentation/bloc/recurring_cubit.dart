import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:invoice_kit/features/business_profile/data/repositories/business_profile_repository.dart';
import 'package:invoice_kit/features/invoices/data/repositories/invoice_repository.dart';
import 'package:invoice_kit/features/recurring/data/repositories/recurring_repository.dart';
import 'package:invoice_kit/features/recurring/domain/entities/recurring_invoice.dart';
import 'package:invoice_kit/features/recurring/domain/usecases/recurring_invoice_generator.dart';
import 'package:invoice_kit/shared/helpers/id_generator.dart';

part 'recurring_event.dart';
part 'recurring_state.dart';

class RecurringCubit extends Cubit<RecurringState> {
  RecurringCubit({
    required this.recurringRepo,
    required this.invoiceRepo,
    required this.businessRepo,
  }) : super(RecurringState.initial());

  final RecurringRepository recurringRepo;
  final InvoiceRepository invoiceRepo;
  final BusinessProfileRepository businessRepo;

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    final schedules = await recurringRepo.all();
    emit(state.copyWith(loading: false, schedules: schedules));
  }

  Future<int> runDue({DateTime? now}) async {
    final current = now ?? DateTime.now();
    final schedules = await recurringRepo.all();
    final profile = await businessRepo.load();
    var generated = 0;

    for (final schedule in schedules.where((s) => s.active)) {
      if (schedule.nextRunDate.isAfter(current)) continue;

      final prefix = profile?.invoicePrefix ?? 'INV-';
      final counter = profile?.nextInvoiceNumber ?? 1;

      final newInvoices = RecurringInvoiceGenerator.generate(
        schedule: schedule,
        now: current,
        invoiceCounter: counter,
        invoicePrefix: prefix,
      );

      for (final invoice in newInvoices) {
        await invoiceRepo.save(invoice);
        generated++;
      }

      if (newInvoices.isNotEmpty) {
        final lastRun = newInvoices.last.issueDate;
        final advanced = RecurringInvoiceGenerator.advance(
          lastRun,
          schedule.frequency,
        );
        final capped =
            (schedule.endDate != null && advanced.isAfter(schedule.endDate!))
            ? schedule.endDate
            : advanced;
        final updatedSchedule = schedule.copyWith(nextRunDate: capped);
        await recurringRepo.save(updatedSchedule);
      }
    }
    await load();
    return generated;
  }

  Future<void> upsert(RecurringInvoice schedule) async {
    final existing = schedule.id.isEmpty
        ? schedule.copyWith(id: IdGenerator.create('rec'))
        : schedule;
    await recurringRepo.save(existing);
    await load();
  }

  Future<void> remove(String id) async {
    await recurringRepo.delete(id);
    await load();
  }
}
