import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
import 'package:invoice_kit/features/business_profile/data/repositories/business_profile_repository.dart';
import 'package:invoice_kit/features/business_profile/domain/entities/business_profile.dart';
import 'package:invoice_kit/features/clients/domain/entities/client.dart';
import 'package:invoice_kit/features/clients/presentation/bloc/clients_cubit.dart';
import 'package:invoice_kit/features/invoices/domain/entities/document.dart'
    show InvoiceStatus;
import 'package:invoice_kit/features/invoices/domain/entities/document_item.dart';
import 'package:invoice_kit/features/invoices/domain/entities/invoice.dart';
import 'package:invoice_kit/features/invoices/domain/services/pdf_generator.dart';
import 'package:invoice_kit/features/invoices/domain/usecases/invoice_calculator.dart';
import 'package:invoice_kit/features/invoices/presentation/bloc/invoices_cubit.dart';
import 'package:invoice_kit/shared/widgets/widgets.dart';
import 'package:printing/printing.dart';

class InvoiceDetailScreen extends StatefulWidget {
  const InvoiceDetailScreen({required this.invoiceId, super.key});
  final String invoiceId;

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
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
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Edit',
          onPressed: () => GoRouter.of(
            context,
          ).push(RoutePaths.invoiceEditPath(widget.invoiceId)),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
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
                await cubit.remove(inv.id);
                if (mounted) GoRouter.of(context).pop();
              case 'pdf':
                await _openPdf(context, inv);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'pdf', child: Text('Preview / share PDF')),
            PopupMenuItem(value: 'sent', child: Text('Mark as sent')),
            PopupMenuItem(value: 'paid', child: Text('Mark as paid')),
            PopupMenuItem(value: 'cancel', child: Text('Mark as cancelled')),
            PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
            PopupMenuDivider(),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ],
      body: BlocBuilder<InvoicesCubit, InvoicesState>(
        builder: (context, state) {
          final inv = state.invoices
              .where((i) => i.id == widget.invoiceId)
              .cast<Invoice?>()
              .firstOrNull;
          if (inv == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return BlocBuilder<ClientsCubit, ClientsState>(
            builder: (context, cstate) {
              final client = cstate.clients
                  .where((c) => c.id == inv.clientId)
                  .cast<Client?>()
                  .firstOrNull;
              return _InvoiceBody(invoice: inv, client: client);
            },
          );
        },
      ),
    );
  }

  Invoice? _invoice(BuildContext context) {
    final s = context.read<InvoicesCubit>().state;
    return s.invoices
        .where((i) => i.id == widget.invoiceId)
        .cast<Invoice?>()
        .firstOrNull;
  }

  Future<void> _openPdf(BuildContext context, Invoice invoice) async {
    final generator = sl<PdfGenerator>();
    final profile =
        await sl<BusinessProfileRepository>().load() ?? _emptyProfile();
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
    );
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Client _emptyClient(String id) =>
      Client(id: id, name: 'Unknown client', createdAt: DateTime.now());

  BusinessProfile _emptyProfile() => const BusinessProfile(businessName: '');
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

class _InvoiceBody extends StatelessWidget {
  const _InvoiceBody({required this.invoice, this.client});
  final Invoice invoice;
  final Client? client;

  @override
  Widget build(BuildContext context) {
    final totals = InvoiceCalculator.forDocument(invoice);
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
                invoice.number,
                style: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            InvoiceStatusBadge(invoice.status),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Billed to ${client?.name ?? "Unknown client"}',
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
                      valueColor: context.colors.primary,
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
