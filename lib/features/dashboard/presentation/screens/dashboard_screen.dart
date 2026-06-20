import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/router/app_routes.dart';
import 'package:invoice_kit/core/router/route_paths.dart';
import 'package:invoice_kit/core/theme/app_colors.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/utils/formatters.dart';
import 'package:invoice_kit/core/widgets/widgets.dart';
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
                          tooltip: 'Reports',
                          onPressed: () =>
                              GoRouter.of(context).go(AppRoutes.reports),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined),
                          tooltip: 'Settings',
                          onPressed: () =>
                              GoRouter.of(context).go(AppRoutes.settings),
                        ),
                      ],
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.xxxl,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          GradientHero.brand(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total revenue',
                                  style: context.textTheme.labelMedium
                                      ?.copyWith(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.6,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  Formatters.currency(
                                    s?.totalRevenue ?? 0,
                                    code: _currency(state),
                                  ),
                                  style: context.textTheme.displaySmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.6,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.trending_up_rounded,
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${s?.paidCount ?? 0} paid · ${s?.sentCount ?? 0} sent',
                                      style: context.textTheme.bodySmall
                                          ?.copyWith(
                                            color: Colors.white.withValues(
                                              alpha: 0.85,
                                            ),
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (subState.isTrialing) ...[
                            const SizedBox(height: AppSpacing.lg),
                            PremiumCard(
                              title: 'Free trial active',
                              subtitle: 'Full access to every feature',
                              icon: Icons.workspace_premium_rounded,
                              cta: 'Upgrade',
                              trialDays: subState.trialDaysRemaining,
                              onTap: () => GoRouter.of(
                                context,
                              ).push(AppRoutes.subscription),
                            ),
                          ],
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
                                label: 'Outstanding',
                                value: Formatters.currency(
                                  s?.outstanding ?? 0,
                                  code: _currency(state),
                                ),
                                icon: Icons.hourglass_bottom_rounded,
                                color: AppColors.warning,
                                subtitle:
                                    '${s?.sentCount ?? 0} sent · ${s?.overdueCount ?? 0} overdue',
                              ),
                              MetricCard(
                                label: 'Paid invoices',
                                value: Formatters.number(s?.paidCount ?? 0),
                                icon: Icons.check_circle_outline,
                                color: AppColors.success,
                              ),
                              MetricCard(
                                label: 'Drafts',
                                value: Formatters.number(s?.draftCount ?? 0),
                                icon: Icons.edit_note_rounded,
                                color: AppColors.statusDraft,
                              ),
                              MetricCard(
                                label: 'Total invoices',
                                value: Formatters.number(s?.totalCount ?? 0),
                                icon: Icons.assignment_outlined,
                                color: context.colors.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          const _QuickActions(),
                          const SizedBox(height: AppSpacing.xl),
                          const SectionHeader(
                            title: 'Recent invoices',
                            uppercase: true,
                            tone: SectionHeaderTone.primary,
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (state.recentInvoices.isEmpty)
                            const AppCard(
                              child: EmptyState(
                                icon: Icons.receipt_long_outlined,
                                title: 'No invoices yet',
                                subtitle: 'Tap "New invoice" to get started.',
                              ),
                            )
                          else
                            ...state.recentInvoices.map((inv) {
                              final client = state.clientsById[inv.clientId];
                              return DocumentRow(
                                title: inv.number,
                                subtitle: client?.name ?? 'Unknown client',
                                amount: inv.total,
                                currency: inv.currency,
                                statusChip: InvoiceStatusBadge(inv.status),
                                onTap: () => GoRouter.of(
                                  context,
                                ).push(RoutePaths.invoiceDetailPath(inv.id)),
                              );
                            }),
                          const SizedBox(height: AppSpacing.xl),
                          const SectionHeader(
                            title: 'Recent clients',
                            uppercase: true,
                            tone: SectionHeaderTone.primary,
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (state.recentClients.isEmpty)
                            const AppCard(
                              child: EmptyState(
                                icon: Icons.people_outline,
                                title: 'No clients yet',
                                subtitle:
                                    'Add your first client to start invoicing.',
                              ),
                            )
                          else
                            AppCard(
                              padding: EdgeInsets.zero,
                              child: Column(
                                children: [
                                  for (
                                    var i = 0;
                                    i < state.recentClients.length;
                                    i++
                                  ) ...[
                                    if (i > 0)
                                      const Divider(
                                        height: 1,
                                        indent: AppSpacing.md,
                                        endIndent: AppSpacing.md,
                                      ),
                                    ClientRow(
                                      name: state.recentClients[i].name,
                                      subtitle:
                                          state.recentClients[i].email ??
                                          state.recentClients[i].company ??
                                          '',
                                      onTap: () => GoRouter.of(context).push(
                                        RoutePaths.clientDetailPath(
                                          state.recentClients[i].id,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
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
    if (state.recentInvoices.isNotEmpty) {
      return state.recentInvoices.first.currency;
    }
    return 'USD';
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.add_box_outlined,
            label: 'New invoice',
            onTap: () => GoRouter.of(context).push(RoutePaths.invoiceNew),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ActionCard(
            icon: Icons.description_outlined,
            label: 'New quote',
            onTap: () => GoRouter.of(context).push(RoutePaths.quoteNew),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ActionCard(
            icon: Icons.person_add_alt_1,
            label: 'New client',
            onTap: () => GoRouter.of(context).push(RoutePaths.clientNew),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      variant: AppCardVariant.tinted,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.md,
      ),
      child: Column(
        children: [
          Icon(icon, color: context.colors.primary, size: 22),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: context.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
