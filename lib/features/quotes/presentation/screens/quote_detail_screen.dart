import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_kit/core/di/injection.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/utils/formatters.dart';
import 'package:invoice_kit/features/clients/domain/entities/client.dart';
import 'package:invoice_kit/features/clients/presentation/bloc/clients_cubit.dart';
import 'package:invoice_kit/features/invoices/data/repositories/invoice_repository.dart';
import 'package:invoice_kit/features/invoices/domain/entities/document.dart' show QuoteStatus;
import 'package:invoice_kit/features/invoices/domain/usecases/invoice_calculator.dart';
import 'package:invoice_kit/features/quotes/domain/entities/quote.dart';
import 'package:invoice_kit/features/quotes/presentation/bloc/quotes_cubit.dart';
import 'package:invoice_kit/shared/widgets/widgets.dart';

class QuoteDetailScreen extends StatefulWidget {
  const QuoteDetailScreen({required this.quoteId, super.key});
  final String quoteId;

  @override
  State<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends State<QuoteDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<QuotesCubit>().load();
    context.read<ClientsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quote'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.go('/quotes/${widget.quoteId}/edit'),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              final cubit = context.read<QuotesCubit>();
              final q = _quote(context);
              if (q == null) return;
              switch (v) {
                case 'accept':
                  await cubit.setStatus(q, QuoteStatus.accepted);
                case 'decline':
                  await cubit.setStatus(q, QuoteStatus.declined);
                case 'send':
                  await cubit.setStatus(q, QuoteStatus.sent);
                case 'convert':
                  final inv = await cubit.convertToInvoice(q);
                  await sl<InvoiceRepository>().save(inv);
                  if (mounted) context.go('/invoices/${inv.id}');
                case 'delete':
                  await cubit.remove(q.id);
                  if (mounted) context.go('/quotes');
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'send', child: Text('Mark as sent')),
              PopupMenuItem(value: 'accept', child: Text('Mark as accepted')),
              PopupMenuItem(value: 'decline', child: Text('Mark as declined')),
              PopupMenuItem(value: 'convert', child: Text('Convert to invoice')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: BlocBuilder<QuotesCubit, QuotesState>(
        builder: (context, state) {
          final q = state.quotes.where((x) => x.id == widget.quoteId).cast<Quote?>().firstOrNull;
          if (q == null) return const Center(child: CircularProgressIndicator());
          return BlocBuilder<ClientsCubit, ClientsState>(
            builder: (context, cstate) {
              final client = cstate.clients.where((c) => c.id == q.clientId).cast<Client?>().firstOrNull;
              return _Body(quote: q, client: client);
            },
          );
        },
      ),
    );
  }

  Quote? _quote(BuildContext context) {
    final s = context.read<QuotesCubit>().state;
    return s.quotes.where((x) => x.id == widget.quoteId).cast<Quote?>().firstOrNull;
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

class _Body extends StatelessWidget {
  const _Body({required this.quote, this.client});
  final Quote quote;
  final Client? client;

  @override
  Widget build(BuildContext context) {
    final totals = InvoiceCalculator.forDocument(quote);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(quote.number, style: context.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            QuoteStatusBadge(quote.status),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Quoted for ${client?.name ?? "Unknown client"}',
          style: context.textTheme.bodyMedium?.copyWith(color: context.colors.outline),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            _meta(context, 'Issued', Formatters.date(quote.issueDate)),
            const SizedBox(width: AppSpacing.md),
            if (quote.validUntil != null) _meta(context, 'Valid until', Formatters.date(quote.validUntil!)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.outlineVariant),
          ),
          child: Column(
            children: [
              ...quote.items.map(
                (it) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(it.description.isEmpty ? '—' : it.description),
                            const SizedBox(height: 2),
                            Text(
                              '${Formatters.number(it.quantity)} × ${Formatters.currency(it.unitPrice)}',
                              style: TextStyle(color: context.colors.outline, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text(Formatters.currency(it.lineTotal)),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              _kv(context, 'Subtotal', totals.subtotal, quote.currency),
              if (totals.lineTax > 0) _kv(context, 'Line tax', totals.lineTax, quote.currency),
              if (totals.globalTax > 0) _kv(context, 'Global tax', totals.globalTax, quote.currency),
              _kv(context, 'Total', totals.total, quote.currency, bold: true),
            ],
          ),
        ),
        if ((quote.notes ?? '').isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Notes', style: context.textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(quote.notes!),
        ],
      ],
    );
  }

  Widget _kv(BuildContext context, String label, double value, String currency, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(label, style: bold ? context.textTheme.titleMedium : context.textTheme.bodyMedium)),
          Text(
            Formatters.currency(value, code: currency),
            style: bold
                ? context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)
                : context.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _meta(BuildContext context, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: context.textTheme.labelSmall?.copyWith(color: context.colors.outline)),
            const SizedBox(height: 4),
            Text(value, style: context.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
