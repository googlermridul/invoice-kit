import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/router/route_paths.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/utils/formatters.dart';
import 'package:invoice_kit/core/widgets/app_scaffold.dart';
import 'package:invoice_kit/core/widgets/empty_state.dart';
import 'package:invoice_kit/features/clients/presentation/bloc/clients_cubit.dart';
import 'package:invoice_kit/features/quotes/presentation/bloc/quotes_cubit.dart';
import 'package:invoice_kit/shared/widgets/widgets.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<QuotesCubit>().load();
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
      body: BlocBuilder<QuotesCubit, QuotesState>(
        builder: (context, state) {
          if (state.loading && state.quotes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.quotes.isEmpty) {
            return EmptyState(
              icon: Icons.description_outlined,
              title: 'No quotes yet',
              subtitle: 'Quotes help you pitch work before invoicing.',
              actionLabel: 'Create quote',
              onAction: () => GoRouter.of(context).push(RoutePaths.quoteNew),
            );
          }
          return BlocBuilder<ClientsCubit, ClientsState>(
            builder: (context, cstate) {
              final byId = {for (final c in cstate.clients) c.id: c};
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xxxl,
                ),
                itemCount: state.quotes.length,
                itemBuilder: (_, i) {
                  final q = state.quotes[i];
                  final client = byId[q.clientId];
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
                },
              );
            },
          );
        },
      ),
    );
  }
}
