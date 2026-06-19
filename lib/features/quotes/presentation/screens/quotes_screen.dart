import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/utils/formatters.dart';
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
  Future<void> initState() async {
    super.initState();
    await context.read<QuotesCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quotes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/quotes/new'),
        icon: const Icon(Icons.add),
        label: const Text('New quote'),
      ),
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
              onAction: () => context.go('/quotes/new'),
            );
          }
          return BlocBuilder<ClientsCubit, ClientsState>(
            builder: (context, cstate) {
              final byId = {for (final c in cstate.clients) c.id: c};
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                itemCount: state.quotes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 2),
                itemBuilder: (_, i) {
                  final q = state.quotes[i];
                  final client = byId[q.clientId];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.colors.outlineVariant),
                    ),
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => context.go('/quotes/${q.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      q.number,
                                      style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  QuoteStatusBadge(q.status),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                client?.name ?? 'Unknown client',
                                style: context.textTheme.bodySmall?.copyWith(color: context.colors.outline),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      Formatters.currency(q.total, code: q.currency),
                                      style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  if (q.validUntil != null)
                                    Text(
                                      'Valid until ${Formatters.date(q.validUntil!)}',
                                      style: context.textTheme.bodySmall?.copyWith(color: context.colors.outline),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
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
