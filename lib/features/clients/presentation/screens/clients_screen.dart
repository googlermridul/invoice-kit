import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/router/route_paths.dart';
import 'package:invoice_kit/core/theme/app_radius.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/widgets/app_scaffold.dart';
import 'package:invoice_kit/core/widgets/empty_state.dart';
import 'package:invoice_kit/core/widgets/search_field.dart';
import 'package:invoice_kit/features/clients/domain/entities/client.dart';
import 'package:invoice_kit/features/clients/presentation/bloc/clients_cubit.dart';
import 'package:invoice_kit/shared/widgets/client_row.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ClientsCubit>().load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Clients',
      leading: const SizedBox.shrink(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => GoRouter.of(context).push(RoutePaths.clientNew),
        icon: const Icon(HugeIconsStroke.plusSign, size: 18),
        label: const Text('New client'),
      ),
      padding: EdgeInsets.zero,
      refreshable: true,
      onRefresh: () => context.read<ClientsCubit>().load(),
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
              hint: 'Search by name, email, company',
              onChanged: (v) => context.read<ClientsCubit>().search(v),
              onClear: () => context.read<ClientsCubit>().load(),
            ),
          ),
          Expanded(
            child: BlocBuilder<ClientsCubit, ClientsState>(
              builder: (context, state) {
                if (state.loading && state.clients.isEmpty) {
                  return ListView(
                    // Keep the RefreshIndicator working while loading.
                    children: const [
                      SizedBox(height: 120),
                      Center(child: CircularProgressIndicator()),
                    ],
                  );
                }
                if (state.clients.isEmpty) {
                  return ListView(
                    children: [
                      const SizedBox(height: 32),
                      EmptyState(
                        icon: Icons.people_outline,
                        title: state.query.isEmpty
                            ? 'No clients yet'
                            : 'No clients match "${state.query}"',
                        subtitle: state.query.isEmpty
                            ? 'Add your first client to start invoicing.'
                            : 'Try a different name or company.',
                        actionLabel: state.query.isEmpty ? 'Add client' : null,
                        onAction: state.query.isEmpty
                            ? () => GoRouter.of(context).push(
                                RoutePaths.clientNew,
                              )
                            : null,
                      ),
                    ],
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xxxl,
                  ),
                  itemCount: state.clients.length,
                  itemBuilder: (_, i) {
                    final c = state.clients[i];
                    final invoices = state.invoiceCountByClient[c.id] ?? 0;
                    final quotes = state.quoteCountByClient[c.id] ?? 0;
                    return ClientRow(
                      name: c.name,
                      subtitle: _clientSubtitle(c),
                      trailing: (invoices > 0 || quotes > 0)
                          ? _CountBadges(invoices: invoices, quotes: quotes)
                          : null,
                      onTap: () => GoRouter.of(context).push(
                        RoutePaths.clientDetailPath(c.id),
                      ),
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

  String? _clientSubtitle(Client c) {
    final parts = [
      if ((c.company ?? '').isNotEmpty) c.company!,
      if ((c.email ?? '').isNotEmpty) c.email!,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

class _CountBadges extends StatelessWidget {
  const _CountBadges({required this.invoices, required this.quotes});
  final int invoices;
  final int quotes;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: [
        if (invoices > 0)
          _Badge(icon: Icons.receipt_long_outlined, n: invoices),
        if (quotes > 0) _Badge(icon: Icons.description_outlined, n: quotes),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.n});
  final IconData icon;
  final int n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: context.colors.primary),
          const SizedBox(width: 4),
          Text(
            '$n',
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
