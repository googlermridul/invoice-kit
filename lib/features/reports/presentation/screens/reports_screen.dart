import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_colors.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/theme/app_tokens.dart';
import 'package:invoice_kit/core/utils/formatters.dart';
import 'package:invoice_kit/core/widgets/widgets.dart';
import 'package:invoice_kit/features/dashboard/presentation/bloc/dashboard_cubit.dart';
import 'package:invoice_kit/features/invoices/domain/entities/document.dart' show InvoiceStatus;
import 'package:invoice_kit/features/reports/domain/usecases/reports_calculator.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Reports',
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state.loading && state.summary == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.summary == null) {
            return const EmptyState(
              icon: Icons.bar_chart_rounded,
              title: 'No data yet',
              subtitle: 'Create a few invoices to see your reports.',
            );
          }
          final calc = const ReportsCalculator();
          final trend = calc.monthlyTrend(state.recentInvoices);
          final top = calc.topClients(
            invoices: state.recentInvoices,
            clientsById: state.clientsById,
            limit: 5,
          );
          final tax = calc.totalTaxCollected(state.recentInvoices);
          final breakdown = calc.statusBreakdown(state.recentInvoices);
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.45,
                children: [
                  MetricCard(
                    label: 'Total revenue',
                    value: Formatters.currency(
                      state.summary!.totalRevenue,
                      code: 'USD',
                    ),
                    icon: Icons.payments_outlined,
                    color: AppColors.success,
                  ),
                  MetricCard(
                    label: 'Outstanding',
                    value: Formatters.currency(
                      state.summary!.outstanding,
                      code: 'USD',
                    ),
                    icon: Icons.hourglass_bottom_rounded,
                    color: AppColors.warning,
                  ),
                  MetricCard(
                    label: 'Tax collected',
                    value: Formatters.currency(tax, code: 'USD'),
                    icon: Icons.receipt_long_outlined,
                    color: AppColors.primary,
                  ),
                  MetricCard(
                    label: 'Invoices',
                    value: Formatters.number(state.summary!.totalCount),
                    icon: Icons.assignment_outlined,
                    color: AppColors.tertiary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(
                title: 'Revenue trend',
                uppercase: true,
                tone: SectionHeaderTone.primary,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: SizedBox(
                  height: 220,
                  child: trend.every((t) => t.amount == 0)
                      ? const Center(child: Text('No paid invoices yet'))
                      : _TrendChart(points: trend),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(
                title: 'Top clients',
                uppercase: true,
                tone: SectionHeaderTone.primary,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (top.isEmpty)
                const AppCard(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: EmptyState(
                      icon: Icons.people_outline,
                      title: 'No client revenue yet',
                    ),
                  ),
                )
              else
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < top.length; i++) ...[
                        if (i > 0)
                          const Divider(
                            height: 1,
                            indent: AppSpacing.md,
                            endIndent: AppSpacing.md,
                          ),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: context.tokens.brandSubtle,
                            child: Text(
                              top[i].client.name.isEmpty ? '?' : top[i].client.name[0].toUpperCase(),
                              style: TextStyle(
                                color: context.colors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          title: Text(
                            top[i].client.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            top[i].client.email ?? top[i].client.company ?? '',
                            style: TextStyle(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                          trailing: Text(
                            Formatters.currency(top[i].total, code: 'USD'),
                            style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(
                title: 'Status breakdown',
                uppercase: true,
                tone: SectionHeaderTone.primary,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSpacing.sm),
              _StatusBreakdown(breakdown: breakdown),
            ],
          );
        },
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.points});
  final List<RevenueTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final maxY = points.fold<double>(0, (m, p) => p.amount > m ? p.amount : m);
    final lineColor = context.colors.primary;
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY == 0 ? 100 : maxY * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    Formatters.monthYear(points[i].period),
                    style: TextStyle(
                      fontSize: 10,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            barWidth: 3,
            color: lineColor,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: lineColor.withValues(alpha: 0.12),
            ),
            spots: [
              for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].amount),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBreakdown extends StatelessWidget {
  const _StatusBreakdown({required this.breakdown});
  final Map<InvoiceStatus, double> breakdown;

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty) {
      return const AppCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Center(child: Text('No data')),
        ),
      );
    }
    return AppCard(
      child: Column(
        children: breakdown.entries.map<Widget>((e) {
          final pct = (e.value * 100).toStringAsFixed(0);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    e.key.name,
                    style: context.textTheme.bodyMedium,
                  ),
                ),
                Text(
                  '$pct%',
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
