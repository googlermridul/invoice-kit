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
import 'package:invoice_kit/features/invoices/domain/entities/document.dart' show InvoiceStatus;
import 'package:invoice_kit/features/invoices/domain/entities/document_item.dart';
import 'package:invoice_kit/features/invoices/domain/entities/invoice.dart';
import 'package:invoice_kit/features/invoices/domain/services/pdf_generator.dart';
import 'package:invoice_kit/features/invoices/domain/usecases/invoice_calculator.dart';
import 'package:invoice_kit/features/invoices/presentation/bloc/invoices_cubit.dart';
import 'package:invoice_kit/shared/dialogs/app_dialog.dart';
import 'package:invoice_kit/shared/widgets/template_preview_header.dart';
import 'package:invoice_kit/shared/widgets/widgets.dart';
import 'package:printing/printing.dart';

class InvoiceDetailScreen extends StatefulWidget {
  const InvoiceDetailScreen({required this.invoiceId, super.key});
  final String invoiceId;

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  /// Cached PDF bytes for the currently viewed invoice. Reused by
  /// Share / Save / Print so we don't re-render the PDF for every action.
  Uint8List? _pdfBytes;

  /// True while the PDF is being built (or a Share/Save/Print is in flight).
  bool _pdfBusy = false;

  @override
  void initState() {
    super.initState();
    context.read<InvoicesCubit>().load();
    context.read<ClientsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Invoice',
      actions: [
        IconButton(
          icon: const Icon(HugeIconsStroke.edit02, size: 18),
          tooltip: 'Edit',
          onPressed: () => GoRouter.of(
            context,
          ).push(RoutePaths.invoiceEditPath(widget.invoiceId)),
        ),
        PopupMenuButton<String>(
          icon: const Icon(HugeIconsStroke.moreVertical),
          onSelected: (v) async {
            final cubit = context.read<InvoicesCubit>();
            final inv = _invoice(context);
            if (inv == null) return;
            switch (v) {
              case 'duplicate':
                final copy = await cubit.duplicate(inv);
                await cubit.saveDuplicate(copy);
                if (mounted) {
                  GoRouter.of(context).pop();
                  GoRouter.of(context).push(
                    RoutePaths.invoiceDetailPath(copy.id),
                  );
                }
              case 'paid':
                await cubit.setStatus(inv, InvoiceStatus.paid);
              case 'sent':
                await cubit.setStatus(inv, InvoiceStatus.sent);
              case 'cancel':
                await cubit.setStatus(inv, InvoiceStatus.cancelled);
              case 'delete':
                final confirmed = await AppDialog.confirm(
                  context: context,
                  title: 'Delete invoice?',
                  message:
                      'This will permanently remove the invoice. '
                      'This cannot be undone.',
                  confirmText: 'Delete',
                  cancelText: 'Cancel',
                  destructive: true,
                );
                if (confirmed != true) break;
                await cubit.remove(inv.id);
                if (mounted) GoRouter.of(context).pop();
              case 'share':
                await _share(context, inv);
              case 'print':
                await _print(context, inv);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'share', child: Text('Share')),
            PopupMenuItem(value: 'print', child: Text('Print')),
            PopupMenuDivider(),
            PopupMenuItem(value: 'sent', child: Text('Mark as sent')),
            PopupMenuItem(value: 'paid', child: Text('Mark as paid')),
            PopupMenuItem(value: 'cancel', child: Text('Mark as cancelled')),
            PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
            PopupMenuDivider(),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ],
      body: FutureBuilder<BusinessProfile?>(
        future: sl<BusinessProfileRepository>().load(),
        builder: (context, snap) {
          final profile = snap.data;
          return BlocBuilder<InvoicesCubit, InvoicesState>(
            builder: (context, state) {
              final inv = state.invoices.where((i) => i.id == widget.invoiceId).cast<Invoice?>().firstOrNull;
              if (inv == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return BlocBuilder<ClientsCubit, ClientsState>(
                builder: (context, cstate) {
                  final client = cstate.clients.where((c) => c.id == inv.clientId).cast<Client?>().firstOrNull;
                  return _InvoiceBody(
                    invoice: inv,
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

  Invoice? _invoice(BuildContext context) {
    final s = context.read<InvoicesCubit>().state;
    return s.invoices.where((i) => i.id == widget.invoiceId).cast<Invoice?>().firstOrNull;
  }

  Future<Uint8List?> _ensureBytes(BuildContext context, Invoice invoice) async {
    final cached = _pdfBytes;
    if (cached != null) return cached;
    if (_pdfBusy) return null;
    setState(() => _pdfBusy = true);
    try {
      final generator = sl<PdfGenerator>();
      final profile = await sl<BusinessProfileRepository>().load() ?? _emptyProfile();
      final client = context
          .read<ClientsCubit>()
          .state
          .clients
          .where((c) => c.id == invoice.clientId)
          .cast<Client?>()
          .firstOrNull;
      final bytes = await generator.invoicePdf(
        invoice: invoice,
        business: profile,
        client: client ?? _emptyClient(invoice.clientId),
        templateId: invoice.pdfTemplateId,
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

  Future<void> _share(BuildContext context, Invoice invoice) async {
    final bytes = await _ensureBytes(context, invoice);
    if (bytes == null || !mounted) return;
    try {
      await sl<DocumentShareService>().share(
        bytes,
        filename: 'Invoice_${invoice.number}.pdf',
        subject: 'InvoiceKit Invoice ${invoice.number}',
      );
    } on Object catch (e) {
      if (mounted) context.showErrorSnack('Could not share: $e');
    }
  }

  Future<void> _print(BuildContext context, Invoice invoice) async {
    final bytes = await _ensureBytes(context, invoice);
    if (bytes == null || !mounted) return;
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Client _emptyClient(String id) => Client(id: id, name: 'Unknown client', createdAt: DateTime.now());

  BusinessProfile _emptyProfile() => const BusinessProfile(businessName: '');
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

class _InvoiceBody extends StatelessWidget {
  const _InvoiceBody({
    required this.invoice,
    this.client,
    this.business,
  });
  final Invoice invoice;
  final Client? client;
  final BusinessProfile? business;

  @override
  Widget build(BuildContext context) {
    final totals = InvoiceCalculator.forDocument(invoice);
    final style = TemplateStyle.forId(
      invoice.pdfTemplateId ?? business?.selectedPdfTemplate,
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
          title: invoice.number,
          subtitle: 'Billed to ${client?.name ?? "Unknown client"}',
          rightLabel: 'TOTAL',
          rightValue: Formatters.currency(
            invoice.total,
            code: invoice.currency,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            InvoiceStatusBadge(invoice.status),
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
                value: Formatters.date(invoice.issueDate),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: MetaTile(
                label: 'Due',
                value: Formatters.date(invoice.dueDate),
              ),
            ),
            if (invoice.paidDate != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: MetaTile(
                  label: 'Paid',
                  value: Formatters.date(invoice.paidDate!),
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
              ...invoice.items.map((it) => _itemRow(context, it)),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    KvRow(
                      label: 'Subtotal',
                      value: Formatters.currency(
                        totals.subtotal,
                        code: invoice.currency,
                      ),
                    ),
                    if (totals.lineTax > 0)
                      KvRow(
                        label: 'Line tax',
                        value: Formatters.currency(
                          totals.lineTax,
                          code: invoice.currency,
                        ),
                      ),
                    if (totals.globalTax > 0)
                      KvRow(
                        label: 'Global tax',
                        value: Formatters.currency(
                          totals.globalTax,
                          code: invoice.currency,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    KvRow(
                      label: 'Total',
                      value: Formatters.currency(
                        totals.total,
                        code: invoice.currency,
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
        if ((invoice.notes ?? '').isNotEmpty) ...[
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
                Text(invoice.notes!),
              ],
            ),
          ),
        ],
        if ((invoice.terms ?? '').isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Terms',
                  uppercase: true,
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(invoice.terms!),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _itemRow(BuildContext context, DocumentItem item) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description.isEmpty ? '—' : item.description,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${Formatters.number(item.quantity)} × ${Formatters.currency(item.unitPrice)}'
                  '${item.taxRate > 0 ? '  · ${item.taxRate.toStringAsFixed(0)}% tax' : ''}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            Formatters.currency(item.lineTotal),
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
