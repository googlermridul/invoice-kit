import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/utils/formatters.dart';
import 'package:invoice_kit/core/widgets/empty_state.dart';
import 'package:invoice_kit/core/widgets/section_header.dart';
import 'package:invoice_kit/features/dashboard/presentation/bloc/dashboard_cubit.dart';
import 'package:invoice_kit/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:invoice_kit/shared/widgets/widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (context, subState) {
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () => context.read<DashboardCubit>().load(),
            child: BlocBuilder<DashboardCubit, DashboardState>(
              builder: (context, state) {
                if (state.loading && state.summary == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.error != null && state.summary == null) {
                  return Center(child: Text(state.error!));
                }
                final s = state.summary;
                return CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      floating: true,
                      title: const Text('InvoiceKit'),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.bar_chart_rounded),
                          onPressed: () => context.go('/reports'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined),
                          onPressed: () => context.go('/settings'),
                        ),
                      ],
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          if (subState.isTrialing)
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.sm),
                              child: PremiumCard(
                                title: 'Free trial active',
                                subtitle: 'Full access to every feature',
                                icon: Icons.workspace_premium_rounded,
                                cta: 'Upgrade',
                                trialDays: subState.trialDaysRemaining,
                                onTap: () => context.go('/subscription'),
                              ),
                            ),
                          const SizedBox(height: AppSpacing.lg),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: AppSpacing.md,
                            mainAxisSpacing: AppSpacing.md,
                            childAspectRatio: 1.4,
                            children: [
                              MetricCard(
                                label: 'Total revenue',
                                value: Formatters.currency(
                                  s?.totalRevenue ?? 0,
                                  code: _currency(state),
                                ),
                                icon: Icons.payments_outlined,
                                color: const Color(0xFF15803D),
                              ),
                              MetricCard(
                                label: 'Outstanding',
                                value: Formatters.currency(
                                  s?.outstanding ?? 0,
                                  code: _currency(state),
                                ),
                                icon: Icons.hourglass_bottom_rounded,
                                color: const Color(0xFFD97706),
                                subtitle: '${s?.sentCount ?? 0} sent · ${s?.overdueCount ?? 0} overdue',
                              ),
                              MetricCard(
                                label: 'Paid invoices',
                                value: Formatters.number(s?.paidCount ?? 0),
                                icon: Icons.check_circle_outline,
                                color: context.colors.primary,
                              ),
                              MetricCard(
                                label: 'Drafts',
                                value: Formatters.number(s?.draftCount ?? 0),
                                icon: Icons.edit_note_rounded,
                                color: const Color(0xFF64748B),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _QuickActions(),
                          const SizedBox(height: AppSpacing.lg),
                          const SectionHeader(title: 'Recent invoices'),
                          if (state.recentInvoices.isEmpty)
                            const EmptyState(
                              icon: Icons.receipt_long_outlined,
                              title: 'No invoices yet',
                              subtitle: 'Tap “New invoice” to get started.',
                            )
                          else
                            ...state.recentInvoices.map((inv) {
                              final client = state.clientsById[inv.clientId];
                              return DocumentListTile(
                                title: inv.number,
                                subtitle: client?.name ?? 'Unknown client',
                                amount: inv.total,
                                currency: inv.currency,
                                trailing: InvoiceStatusBadge(inv.status),
                                onTap: () => context.go('/invoices/${inv.id}'),
                              );
                            }),
                          const SizedBox(height: AppSpacing.lg),
                          const SectionHeader(title: 'Recent clients'),
                          if (state.recentClients.isEmpty)
                            const EmptyState(
                              icon: Icons.people_outline,
                              title: 'No clients yet',
                              subtitle: 'Add your first client to start invoicing.',
                            )
                          else
                            ...state.recentClients.map(
                              (c) => ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: context.colors.primary.withValues(alpha: 0.12),
                                  child: Text(
                                    c.name.isEmpty ? '?' : c.name[0].toUpperCase(),
                                    style: TextStyle(color: context.colors.primary),
                                  ),
                                ),
                                title: Text(c.name),
                                subtitle: Text(c.email ?? c.company ?? ''),
                                onTap: () => context.go('/clients/${c.id}'),
                              ),
                            ),
                          const SizedBox(height: 80),
                        ]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _currency(DashboardState state) {
    if (state.recentInvoices.isNotEmpty) return state.recentInvoices.first.currency;
    return 'USD';
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.add_box_outlined,
            label: 'New invoice',
            onTap: () => context.go('/invoices/new'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ActionCard(
            icon: Icons.description_outlined,
            label: 'New quote',
            onTap: () => context.go('/quotes/new'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ActionCard(
            icon: Icons.person_add_alt_1,
            label: 'New client',
            onTap: () => context.go('/clients/new'),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: context.colors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.primary.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Icon(icon, color: context.colors.primary, size: 22),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: context.textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}
