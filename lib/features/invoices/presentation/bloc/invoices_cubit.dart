import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:invoice_kit/features/business_profile/data/repositories/business_profile_repository.dart';
import 'package:invoice_kit/features/invoices/data/repositories/invoice_repository.dart';
import 'package:invoice_kit/features/invoices/domain/entities/document.dart'
    show InvoiceStatus;
import 'package:invoice_kit/features/invoices/domain/entities/document_item.dart';
import 'package:invoice_kit/features/invoices/domain/entities/invoice.dart';
import 'package:invoice_kit/features/invoices/domain/usecases/invoice_calculator.dart';
import 'package:invoice_kit/shared/helpers/id_generator.dart';

part 'invoices_event.dart';
part 'invoices_state.dart';

class InvoicesCubit extends Cubit<InvoicesState> {
  InvoicesCubit({
    required this.invoiceRepo,
    required this.businessRepo,
  }) : super(InvoicesState.initial());

  final InvoiceRepository invoiceRepo;
  final BusinessProfileRepository businessRepo;

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final all = await invoiceRepo.all();
      final profile = await businessRepo.load();
      final now = DateTime.now();
      final updated = all.map((i) {
        if (i.isOverdueOn(now) && i.status == InvoiceStatus.sent) {
          return i.copyWith(status: InvoiceStatus.overdue);
        }
        return i;
      }).toList();
      for (final inv in updated.where(
        (i) => i.status == InvoiceStatus.overdue,
      )) {
        if (all.firstWhere((a) => a.id == inv.id).status !=
            InvoiceStatus.overdue) {
          await invoiceRepo.save(inv);
        }
      }
      final sorted = [...updated]
        ..sort((a, b) => b.issueDate.compareTo(a.issueDate));
      emit(
        state.copyWith(
          loading: false,
          invoices: sorted,
          defaultCurrency: profile?.defaultCurrency,
        ),
      );
    } on Exception catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> remove(String id) async {
    emit(state.copyWith(clearError: true));
    try {
      await invoiceRepo.delete(id);
      await load();
    } on Exception catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<Invoice> duplicate(Invoice invoice, {String? newNumber}) async {
    final profile = await businessRepo.load();
    final nextNumber = profile?.nextInvoiceNumber ?? 1;
    final copy = invoice.copyWith(
      id: IdGenerator.create('inv'),
      number:
          newNumber ??
          '${profile?.invoicePrefix ?? 'INV-'}${nextNumber.toString().padLeft(5, '0')}',
      status: InvoiceStatus.draft,
      issueDate: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 14)),
      paidDate: null,
      pdfTemplateId: invoice.pdfTemplateId,
      items: invoice.items
          .map((it) => it.copyWith(description: it.description))
          .toList(),
    );
    return copy;
  }

  Future<void> saveDuplicate(Invoice invoice) async {
    await invoiceRepo.save(invoice);
    await load();
  }

  Future<void> setStatus(Invoice invoice, InvoiceStatus status) async {
    final updated = invoice.copyWith(
      status: status,
      paidDate: status == InvoiceStatus.paid ? DateTime.now() : null,
    );
    await invoiceRepo.save(updated);
    await load();
  }

  Future<Invoice> createDraft({
    required String clientId,
    String currency = 'USD',
  }) async {
    final profile = await businessRepo.load();
    final number =
        '${profile?.invoicePrefix ?? 'INV-'}${(profile?.nextInvoiceNumber ?? 1).toString().padLeft(5, '0')}';
    final now = DateTime.now();
    return Invoice(
      id: IdGenerator.create('inv'),
      number: number,
      clientId: clientId,
      issueDate: now,
      dueDate: now.add(const Duration(days: 14)),
      currency: currency,
      items: [DocumentItem.empty(IdGenerator.create('item'))],
      notes: profile?.defaultNotes,
      terms: profile?.defaultPaymentTerms,
      status: InvoiceStatus.draft,
      pdfTemplateId: profile?.selectedPdfTemplate,
    );
  }

  Totals computeTotals(List<DocumentItem> items, {double? taxRateOverride}) =>
      InvoiceCalculator.forDocument(_virtualDoc(items, taxRateOverride));

  Invoice _virtualDoc(List<DocumentItem> items, double? taxRateOverride) {
    final now = DateTime.now();
    return Invoice(
      id: '',
      number: '',
      clientId: '',
      issueDate: now,
      dueDate: now,
      currency: 'USD',
      items: items,
      taxRateOverride: taxRateOverride,
      status: InvoiceStatus.draft,
    );
  }
}
