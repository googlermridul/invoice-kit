import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:invoice_kit/features/clients/data/repositories/client_repository.dart';
import 'package:invoice_kit/features/clients/domain/entities/client.dart';
import 'package:invoice_kit/features/invoices/data/repositories/invoice_repository.dart';
import 'package:invoice_kit/features/invoices/domain/entities/invoice.dart';
import 'package:invoice_kit/features/quotes/data/repositories/quote_repository.dart';
import 'package:invoice_kit/features/quotes/domain/entities/quote.dart';
import 'package:invoice_kit/features/reports/domain/usecases/reports_calculator.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({
    required this.invoiceRepo,
    required this.clientRepo,
    required this.quoteRepo,
  }) : super(DashboardState.initial());

  final InvoiceRepository invoiceRepo;
  final ClientRepository clientRepo;
  final QuoteRepository quoteRepo;
  final ReportsCalculator calc = const ReportsCalculator();

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final invoices = await invoiceRepo.all();
      final quotes = await quoteRepo.all();
      final clients = await clientRepo.all();
      final clientsById = {for (final c in clients) c.id: c};

      final now = DateTime.now();
      final summary = calc.summarize(invoices, now);

      final sortedInvoices = [...invoices]..sort((a, b) => b.issueDate.compareTo(a.issueDate));

      final sortedClients = [...clients]
        ..sort((a, b) {
          final ad = a.createdAt ?? DateTime(2000);
          final bd = b.createdAt ?? DateTime(2000);
          return bd.compareTo(ad);
        });

      emit(
        state.copyWith(
          loading: false,
          summary: summary,
          recentInvoices: sortedInvoices.take(5).toList(),
          recentClients: sortedClients.take(5).toList(),
          recentQuotes: quotes.take(5).toList(),
          clientsById: clientsById,
        ),
      );
    } on Exception catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }
}
