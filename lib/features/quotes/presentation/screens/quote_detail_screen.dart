import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:invoice_kit/core/di/injection.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/router/route_paths.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/utils/formatters.dart';
import 'package:invoice_kit/core/widgets/app_card.dart';
import 'package:invoice_kit/core/widgets/app_scaffold.dart';
import 'package:invoice_kit/core/widgets/kv_row.dart';
import 'package:invoice_kit/core/widgets/meta_tile.dart';
import 'package:invoice_kit/core/widgets/section_header.dart';
import 'package:invoice_kit/features/clients/domain/entities/client.dart';
import 'package:invoice_kit/features/clients/presentation/bloc/clients_cubit.dart';
import 'package:invoice_kit/features/invoices/data/repositories/invoice_repository.dart';
import 'package:invoice_kit/features/invoices/domain/entities/document.dart' show QuoteStatus;
import 'package:invoice_kit/features/invoices/domain/usecases/invoice_calculator.dart';
import 'package:invoice_kit/features/quotes/domain/entities/quote.dart';
import 'package:invoice_kit/features/quotes/presentation/bloc/quotes_cubit.dart';
import 'package:invoice_kit/shared/dialogs/app_dialog.dart';
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
    unawaited(context.read<QuotesCubit>().load());
    unawaited(context.read<ClientsCubit>().load());
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Quote',
      actions: [
        IconButton(
          icon: const Icon(HugeIconsStroke.edit02, size: 18),
          tooltip: 'Edit',
          onPressed: () => GoRouter.of(context).push(
            RoutePaths.quoteEditPath(widget.quoteId),
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(HugeIconsStroke.moreVertical),
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
                if (mounted) {
                  GoRouter.of(context).pushReplacement('/invoices/${inv.id}');
                }
              case 'delete':
                final confirmed = await AppDialog.confirm(
                  context: context,
                  title: 'Delete quote?',
                  message:
                      'This will permanently remove the quote. '
                      'This cannot be undone.',
                  confirmText: 'Delete',
                  cancelText: 'Cancel',
                  destructive: true,
                );
                if (confirmed != true) break;
                await cubit.remove(q.id);
                if (mounted) GoRouter.of(context).pop();
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
      body: BlocBuilder<QuotesCubit, QuotesState>(
        builder: (context, state) {
          final q = state.quotes.where((x) => x.id == widget.quoteId).cast<Quote?>().firstOrNull;
          if (q == null) {
            return const Center(child: CircularProgressIndicator());
          }
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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                quote.number,
                style: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            QuoteStatusBadge(quote.status),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Quoted for ${client?.name ?? "Unknown client"}',
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: MetaTile(
                label: 'Issued',
                value: Formatters.date(quote.issueDate),
              ),
            ),
            if (quote.validUntil != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: MetaTile(
                  label: 'Valid until',
                  value: Formatters.date(quote.validUntil!),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        AppCard(
          padding: EdgeInsets.zero,
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
                            Text(
                              it.description.isEmpty ? '—' : it.description,
                              style: context.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${Formatters.number(it.quantity)} × ${Formatters.currency(it.unitPrice)}',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        Formatters.currency(it.lineTotal),
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    KvRow(
                      label: 'Subtotal',
                      value: Formatters.currency(
                        totals.subtotal,
                        code: quote.currency,
                      ),
                    ),
                    if (totals.lineTax > 0)
                      KvRow(
                        label: 'Line tax',
                        value: Formatters.currency(
                          totals.lineTax,
                          code: quote.currency,
                        ),
                      ),
                    if (totals.globalTax > 0)
                      KvRow(
                        label: 'Global tax',
                        value: Formatters.currency(
                          totals.globalTax,
                          code: quote.currency,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    KvRow(
                      label: 'Total',
                      value: Formatters.currency(
                        totals.total,
                        code: quote.currency,
                      ),
                      bold: true,
                      valueColor: context.colors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if ((quote.notes ?? '').isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Notes',
                  uppercase: true,
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(quote.notes!),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
