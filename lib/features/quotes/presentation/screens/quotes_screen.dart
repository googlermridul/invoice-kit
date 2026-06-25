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
import 'package:invoice_kit/features/quotes/presentation/bloc/quotes_cubit.dart';
import 'package:invoice_kit/shared/widgets/document_filter_sheet.dart';
import 'package:invoice_kit/shared/widgets/widgets.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  DocumentFilter _filter = DocumentFilter.empty;

  @override
  void initState() {
    super.initState();
    // Fire-and-forget loading; ignore unawaited futures.
    unawaited(context.read<QuotesCubit>().load());
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
      title: 'Quotes',
      leading: const SizedBox.shrink(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => GoRouter.of(context).push(RoutePaths.quoteNew),
        icon: const Icon(HugeIconsStroke.plusSign, size: 18),
        label: const Text('New quote'),
      ),
      padding: EdgeInsets.zero,
      refreshable: true,
      onRefresh: () => context.read<QuotesCubit>().load(),
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
            child: BlocBuilder<QuotesCubit, QuotesState>(
              builder: (context, state) {
                if (state.loading && state.quotes.isEmpty) {
                  return ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: CircularProgressIndicator()),
                    ],
                  );
                }
                return BlocBuilder<ClientsCubit, ClientsState>(
                  builder: (context, cstate) {
                    // Lookup table for resolving client name per quote so
                    // search-by-client-name and display both work.
                    final clientsById = {
                      for (final c in cstate.clients) c.id.trim(): c,
                    };
                    final filtered = filterQuotes(
                      quotes: state.quotes,
                      filter: _filter,
                      query: _query,
                      resolveClientName: (q) =>
                          clientsById[q.clientId.trim()]?.name,
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
                          isInvoice: false,
                          onChanged: (f) => setState(() => _filter = f),
                          onClear: () =>
                              setState(() => _filter = DocumentFilter.empty),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${filtered.length} of ${state.quotes.length}',
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                final updated =
                                    await DocumentFilterSheet.show(
                                  context: context,
                                  initial: _filter,
                                  isInvoice: false,
                                );
                                if (updated != null) {
                                  setState(() => _filter = updated);
                                }
                              },
                              icon: Icon(
                                Icons.tune,
                                color: _filter.activeCount > 0
                                    ? context.colors.primary
                                    : null,
                              ),
                              label: Text(
                                _filter.activeCount > 0
                                    ? 'Filters · ${_filter.activeCount}'
                                    : 'Filters',
                                style: TextStyle(
                                  color: _filter.activeCount > 0
                                      ? context.colors.primary
                                      : null,
                                  fontWeight: _filter.activeCount > 0
                                      ? FontWeight.w700
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (filtered.isEmpty)
                          EmptyState(
                            icon: Icons.description_outlined,
                            title: _query.isNotEmpty || !_filter.isEmpty
                                ? 'No quotes match your filters'
                                : 'No quotes yet',
                            subtitle: _query.isNotEmpty || !_filter.isEmpty
                                ? 'Try clearing search or filters.'
                                : 'Quotes help you pitch work before invoicing.',
                            actionLabel: _query.isEmpty && _filter.isEmpty
                                ? 'Create quote'
                                : null,
                            onAction: _query.isEmpty && _filter.isEmpty
                                ? () => GoRouter.of(context)
                                    .push(RoutePaths.quoteNew)
                                : null,
                          )
                        else
                          ...filtered.map((q) {
                            final client = clientsById[q.clientId.trim()];
                            return DocumentRow(
                              title: q.number,
                              subtitle: client?.name ?? 'Unknown client',
                              amount: q.total,
                              currency: q.currency,
                              statusChip: QuoteStatusBadge(q.status),
                              amountTrailing: q.validUntil == null
                                  ? null
                                  : Text(
                                      'Valid until ${Formatters.date(q.validUntil!)}',
                                      style: context.textTheme.bodySmall?.copyWith(
                                        color: context.colors.onSurfaceVariant,
                                      ),
                                    ),
                              onTap: () => GoRouter.of(context).push(
                                RoutePaths.quoteDetailPath(q.id),
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
