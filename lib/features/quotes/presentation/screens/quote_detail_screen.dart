import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:invoice_kit/core/di/injection.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/router/route_paths.dart';
import 'package:invoice_kit/core/services/document_share_service.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/utils/formatters.dart';
import 'package:invoice_kit/core/widgets/app_card.dart';
import 'package:invoice_kit/core/widgets/app_scaffold.dart';
import 'package:invoice_kit/core/widgets/kv_row.dart';
import 'package:invoice_kit/core/widgets/meta_tile.dart';
import 'package:invoice_kit/core/widgets/section_header.dart';
import 'package:invoice_kit/features/business_profile/data/repositories/business_profile_repository.dart';
import 'package:invoice_kit/features/business_profile/domain/entities/business_profile.dart';
import 'package:invoice_kit/features/clients/domain/entities/client.dart';
import 'package:invoice_kit/features/clients/presentation/bloc/clients_cubit.dart';
import 'package:invoice_kit/features/invoices/data/repositories/invoice_repository.dart';
import 'package:invoice_kit/features/invoices/domain/entities/document.dart'
    show QuoteStatus;
import 'package:invoice_kit/features/invoices/domain/services/pdf_generator.dart';
import 'package:invoice_kit/features/invoices/domain/usecases/invoice_calculator.dart';
import 'package:invoice_kit/features/quotes/domain/entities/quote.dart';
import 'package:invoice_kit/features/quotes/presentation/bloc/quotes_cubit.dart';
import 'package:invoice_kit/shared/dialogs/app_dialog.dart';
import 'package:invoice_kit/shared/widgets/template_preview_header.dart';
import 'package:invoice_kit/shared/widgets/widgets.dart';
import 'package:printing/printing.dart';

class QuoteDetailScreen extends StatefulWidget {
  const QuoteDetailScreen({required this.quoteId, super.key});
  final String quoteId;

  @override
  State<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends State<QuoteDetailScreen> {
  /// Cached PDF bytes for the currently viewed quote. Reused by
  /// Share / Save / Print so we don't re-render the PDF for every action.
  Uint8List? _pdfBytes;

  /// True while the PDF is being built (or a Share/Save/Print is in flight).
  bool _pdfBusy = false;

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
              case 'share':
                await _share(context, q);
              case 'print':
                await _print(context, q);
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
            PopupMenuItem(value: 'share', child: Text('Share')),
            PopupMenuItem(value: 'print', child: Text('Print')),
            PopupMenuDivider(),
            PopupMenuItem(value: 'send', child: Text('Mark as sent')),
            PopupMenuItem(value: 'accept', child: Text('Mark as accepted')),
            PopupMenuItem(value: 'decline', child: Text('Mark as declined')),
            PopupMenuItem(value: 'convert', child: Text('Convert to invoice')),
            PopupMenuDivider(),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ],
      body: FutureBuilder<BusinessProfile?>(
        future: sl<BusinessProfileRepository>().load(),
        builder: (context, snap) {
          final profile = snap.data;
          return BlocBuilder<QuotesCubit, QuotesState>(
            builder: (context, state) {
              final q = state.quotes
                  .where((x) => x.id == widget.quoteId)
                  .cast<Quote?>()
                  .firstOrNull;
              if (q == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return BlocBuilder<ClientsCubit, ClientsState>(
                builder: (context, cstate) {
                  final client = cstate.clients
                      .where((c) => c.id == q.clientId)
                      .cast<Client?>()
                      .firstOrNull;
                  return _Body(
                    quote: q,
                    client: client,
                    business: profile,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Quote? _quote(BuildContext context) {
    final s = context.read<QuotesCubit>().state;
    return s.quotes
        .where((x) => x.id == widget.quoteId)
        .cast<Quote?>()
        .firstOrNull;
  }

  Future<Uint8List?> _ensureBytes(BuildContext context, Quote quote) async {
    final cached = _pdfBytes;
    if (cached != null) return cached;
    if (_pdfBusy) return null;
    setState(() => _pdfBusy = true);
    try {
      final generator = sl<PdfGenerator>();
      final profile =
          await sl<BusinessProfileRepository>().load() ?? _emptyProfile();
      final client = context
          .read<ClientsCubit>()
          .state
          .clients
          .where((c) => c.id == quote.clientId)
          .cast<Client?>()
          .firstOrNull;
      final bytes = await generator.quotePdf(
        quote: quote,
        business: profile,
        client: client ?? _emptyClient(quote.clientId),
        templateId: quote.pdfTemplateId,
      );
      _pdfBytes = bytes;
      return bytes;
    } on Object catch (e) {
      if (mounted) context.showErrorSnack('Could not build PDF: $e');
      return null;
    } finally {
      if (mounted) setState(() => _pdfBusy = false);
    }
  }

  Future<void> _share(BuildContext context, Quote quote) async {
    final bytes = await _ensureBytes(context, quote);
    if (bytes == null || !mounted) return;
    try {
      await sl<DocumentShareService>().share(
        bytes,
        filename: 'Quote_${quote.number}.pdf',
        subject: 'InvoiceKit Quote ${quote.number}',
      );
    } on Object catch (e) {
      if (mounted) context.showErrorSnack('Could not share: $e');
    }
  }

  Future<void> _print(BuildContext context, Quote quote) async {
    final bytes = await _ensureBytes(context, quote);
    if (bytes == null || !mounted) return;
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Client _emptyClient(String id) =>
      Client(id: id, name: 'Unknown client', createdAt: DateTime.now());

  BusinessProfile _emptyProfile() => const BusinessProfile(businessName: '');
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

class _Body extends StatelessWidget {
  const _Body({required this.quote, this.client, this.business});
  final Quote quote;
  final Client? client;
  final BusinessProfile? business;

  @override
  Widget build(BuildContext context) {
    final totals = InvoiceCalculator.forDocument(quote);
    final style = TemplateStyle.forId(
      quote.pdfTemplateId ?? business?.selectedPdfTemplate,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xxxl,
      ),
      children: [
        TemplatePreviewHeader(
          style: style,
          title: quote.number,
          subtitle: 'Quoted for ${client?.name ?? "Unknown client"}',
          rightLabel: 'TOTAL',
          rightValue: Formatters.currency(
            quote.total,
            code: quote.currency,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            QuoteStatusBadge(quote.status),
            const Spacer(),
            Text(
              'Template · ${style.label}',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ],
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
                      valueColor: style.accent,
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
