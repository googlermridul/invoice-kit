import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_colors.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/utils/formatters.dart';
import 'package:invoice_kit/core/widgets/empty_state.dart';
import 'package:invoice_kit/features/dashboard/presentation/bloc/dashboard_cubit.dart';
import 'package:invoice_kit/features/reports/domain/usecases/reports_calculator.dart';
import 'package:invoice_kit/shared/widgets/widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  Future<void> initState() async {
    super.initState();
    await context.read<DashboardCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state.loading) return const Center(child: CircularProgressIndicator());
          if (state.summary == null) {
            return const Center(child: Text('No data yet.'));
          }
          final calc = const ReportsCalculator();
          final trend = calc.monthlyTrend(state.recentInvoices);
          final top = calc.topClients(
            invoices: state.recentInvoices,
            clientsById: state.clientsById,
            limit: 5,
          );
          final tax = calc.totalTaxCollected(state.recentInvoices);
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.5,
                children: [
                  MetricCard(
                    label: 'Total revenue',
                    value: Formatters.currency(state.summary!.totalRevenue, code: 'USD'),
                    icon: Icons.payments_outlined,
                    color: AppColors.success,
                  ),
                  MetricCard(
                    label: 'Outstanding',
                    value: Formatters.currency(state.summary!.outstanding, code: 'USD'),
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
                    color: AppColors.primaryAccent,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Revenue trend', style: context.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Container(
                height: 220,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.colors.outlineVariant),
                ),
                child: trend.every((t) => t.amount == 0)
                    ? const Center(child: Text('No paid invoices yet'))
                    : _TrendChart(points: trend),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Top clients', style: context.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              if (top.isEmpty)
                const EmptyState(icon: Icons.people_outline, title: 'No client revenue yet')
              else
                ...top.map(
                  (c) => ListTile(
                    title: Text(c.client.name),
                    subtitle: Text(c.client.email ?? c.client.company ?? ''),
                    trailing: Text(
                      Formatters.currency(c.total, code: 'USD'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              Text('Status breakdown', style: context.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              _StatusBreakdown(
                breakdown: calc.statusBreakdown(state.recentInvoices),
              ),
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
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY == 0 ? 100 : maxY * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                  child: Text(Formatters.monthYear(points[i].period), style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            barWidth: 3,
            color: AppColors.primary,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.12),
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
  final Map<dynamic, dynamic> breakdown;

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Text('No data'),
      );
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Column(
        children: breakdown.entries.map<Widget>((e) {
          final pct = (e.value * 100).toStringAsFixed(0);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: Text('${e.key.name}')),
                Text('$pct%'),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
