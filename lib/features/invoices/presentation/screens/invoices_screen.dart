import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/filters/document_filter.dart';
import 'package:invoice_kit/core/router/route_paths.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/utils/formatters.dart';
import 'package:invoice_kit/core/widgets/app_scaffold.dart';
import 'package:invoice_kit/core/widgets/empty_state.dart';
import 'package:invoice_kit/core/widgets/search_field.dart';
import 'package:invoice_kit/features/clients/presentation/bloc/clients_cubit.dart';
import 'package:invoice_kit/features/invoices/presentation/bloc/invoices_cubit.dart';
import 'package:invoice_kit/shared/widgets/document_filter_sheet.dart';
import 'package:invoice_kit/shared/widgets/widgets.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  DocumentFilter _filter = DocumentFilter.empty;

  @override
  void initState() {
    super.initState();
    // Fire-and-forget loading; ignore unawaited futures.
    unawaited(context.read<InvoicesCubit>().load());
    unawaited(context.read<ClientsCubit>().load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Invoices',
      leading: const SizedBox.shrink(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => GoRouter.of(context).push(RoutePaths.invoiceNew),
        icon: const Icon(HugeIconsStroke.plusSign, size: 18),
        label: const Text('New invoice'),
      ),
      padding: EdgeInsets.zero,
      refreshable: true,
      onRefresh: () => context.read<InvoicesCubit>().load(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: SearchField(
              controller: _searchCtrl,
              hint: 'Search by number, client, notes…',
              onChanged: (v) => setState(() => _query = v),
              onClear: () {
                _searchCtrl.clear();
                setState(() => _query = '');
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<InvoicesCubit, InvoicesState>(
              builder: (context, state) {
                if (state.loading && state.invoices.isEmpty) {
                  return ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: CircularProgressIndicator()),
                    ],
                  );
                }
                return BlocBuilder<ClientsCubit, ClientsState>(
                  builder: (context, cstate) {
                    // Lookup table for resolving client name per invoice so
                    // search-by-client-name and display both work.
                    final clientsById = {
                      for (final c in cstate.clients) c.id.trim(): c,
                    };
                    final filtered = filterInvoices(
                      invoices: state.invoices,
                      filter: _filter,
                      query: _query,
                      resolveClientName: (inv) =>
                          clientsById[inv.clientId.trim()]?.name,
                    );
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.xs,
                        AppSpacing.lg,
                        AppSpacing.xxxl,
                      ),
                      children: [
                        DocumentFilterChips(
                          filter: _filter,
                          isInvoice: true,
                          onChanged: (f) => setState(() => _filter = f),
                          onClear: () => setState(() => _filter = DocumentFilter.empty),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${filtered.length} of ${state.invoices.length}',
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                final updated = await DocumentFilterSheet.show(
                                  context: context,
                                  initial: _filter,
                                  isInvoice: true,
                                );
                                if (updated != null) {
                                  setState(() => _filter = updated);
                                }
                              },
                              icon: Icon(
                                Icons.tune,
                                color: _filter.activeCount > 0 ? context.colors.primary : null,
                              ),
                              label: Text(
                                _filter.activeCount > 0 ? 'Filters · ${_filter.activeCount}' : 'Filters',
                                style: TextStyle(
                                  color: _filter.activeCount > 0 ? context.colors.primary : null,
                                  fontWeight: _filter.activeCount > 0 ? FontWeight.w700 : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (filtered.isEmpty)
                          EmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: _query.isNotEmpty || !_filter.isEmpty
                                ? 'No invoices match your filters'
                                : 'No invoices yet',
                            subtitle: _query.isNotEmpty || !_filter.isEmpty
                                ? 'Try clearing search or filters.'
                                : 'Create your first invoice to bill a client.',
                            actionLabel: _query.isEmpty && _filter.isEmpty ? 'Create invoice' : null,
                            onAction: _query.isEmpty && _filter.isEmpty
                                ? () => GoRouter.of(
                                    context,
                                  ).push(RoutePaths.invoiceNew)
                                : null,
                          )
                        else
                          ...filtered.map((inv) {
                            final client = clientsById[inv.clientId.trim()];
                            return DocumentRow(
                              title: inv.number,
                              subtitle: client?.name ?? 'Unknown client',
                              amount: inv.total,
                              currency: inv.currency,
                              statusChip: InvoiceStatusBadge(inv.status),
                              amountTrailing: Text(
                                'Due ${Formatters.date(inv.dueDate)}',
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                              onTap: () => GoRouter.of(context).push(
                                RoutePaths.invoiceDetailPath(inv.id),
                              ),
                            );
                          }),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
