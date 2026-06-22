import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:invoice_kit/features/business_profile/data/repositories/business_profile_repository.dart';
import 'package:invoice_kit/features/invoices/domain/entities/document.dart'
    show InvoiceStatus, QuoteStatus;
import 'package:invoice_kit/features/invoices/domain/entities/document_item.dart';
import 'package:invoice_kit/features/invoices/domain/entities/invoice.dart';
import 'package:invoice_kit/features/quotes/data/repositories/quote_repository.dart';
import 'package:invoice_kit/features/quotes/domain/entities/quote.dart';
import 'package:invoice_kit/shared/helpers/id_generator.dart';

part 'quotes_event.dart';
part 'quotes_state.dart';

class QuotesCubit extends Cubit<QuotesState> {
  QuotesCubit({
    required this.quoteRepo,
    required this.businessRepo,
  }) : super(QuotesState.initial());

  final QuoteRepository quoteRepo;
  final BusinessProfileRepository businessRepo;

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final all = await quoteRepo.all();
      final profile = await businessRepo.load();
      final sorted = [...all]
        ..sort((a, b) => b.issueDate.compareTo(a.issueDate));
      emit(
        state.copyWith(
          loading: false,
          quotes: sorted,
          defaultCurrency: profile?.defaultCurrency,
        ),
      );
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> remove(String id) async {
    emit(state.copyWith(clearError: true));
    try {
      await quoteRepo.delete(id);
      await load();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<Quote> duplicate(Quote quote, {String? newNumber}) async {
    final profile = await businessRepo.load();
    final nextNumber = profile?.nextQuoteNumber ?? 1;
    final copy = quote.copyWith(
      id: IdGenerator.create('quo'),
      number:
          newNumber ??
          '${profile?.quotePrefix ?? 'QUO-'}${nextNumber.toString().padLeft(5, '0')}',
      status: QuoteStatus.draft,
      issueDate: DateTime.now(),
      validUntil: DateTime.now().add(const Duration(days: 30)),
      items: quote.items
          .map((it) => it.copyWith(description: it.description))
          .toList(),
    );
    return copy;
  }

  Future<void> saveDuplicate(Quote quote) async {
    await quoteRepo.save(quote);
    await load();
  }

  Future<void> setStatus(Quote quote, QuoteStatus status) async {
    final updated = quote.copyWith(status: status);
    await quoteRepo.save(updated);
    await load();
  }

  Future<Quote> createDraft({
    required String clientId,
    String currency = 'USD',
  }) async {
    final profile = await businessRepo.load();
    final number =
        '${profile?.quotePrefix ?? 'QUO-'}${(profile?.nextQuoteNumber ?? 1).toString().padLeft(5, '0')}';
    final now = DateTime.now();
    return Quote(
      id: IdGenerator.create('quo'),
      number: number,
      clientId: clientId,
      issueDate: now,
      dueDate: now.add(const Duration(days: 30)),
      currency: currency,
      items: [DocumentItem.empty(IdGenerator.create('item'))],
      notes: profile?.defaultNotes,
      status: QuoteStatus.draft,
      pdfTemplateId: profile?.selectedPdfTemplate,
    );
  }

  Future<Invoice> convertToInvoice(Quote quote) async {
    final profile = await businessRepo.load();
    final nextNumber = profile?.nextInvoiceNumber ?? 1;
    final number =
        '${profile?.invoicePrefix ?? 'INV-'}${nextNumber.toString().padLeft(5, '0')}';
    final now = DateTime.now();
    return Invoice(
      id: IdGenerator.create('inv'),
      number: number,
      clientId: quote.clientId,
      issueDate: now,
      dueDate: now.add(const Duration(days: 14)),
      currency: quote.currency,
      items: quote.items,
      notes: quote.notes,
      terms: quote.terms ?? profile?.defaultPaymentTerms,
      taxRateOverride: quote.taxRateOverride,
      status: InvoiceStatus.draft,
      pdfTemplateId: quote.pdfTemplateId,
    );
  }
}
