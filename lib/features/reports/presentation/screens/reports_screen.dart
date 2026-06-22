import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_colors.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/theme/app_tokens.dart';
import 'package:invoice_kit/core/utils/formatters.dart';
import 'package:invoice_kit/core/widgets/widgets.dart';
import 'package:invoice_kit/features/dashboard/presentation/bloc/dashboard_cubit.dart';
import 'package:invoice_kit/features/invoices/domain/entities/document.dart' show InvoiceStatus;
import 'package:invoice_kit/features/reports/data/services/report_pdf_service.dart';
import 'package:invoice_kit/features/reports/domain/usecases/reports_calculator.dart';
import 'package:invoice_kit/shared/widgets/buttons.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late DateTime _start;
  late DateTime _end;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _end = DateTime(now.year, now.month, now.day);
    _start = _end.subtract(const Duration(days: 90));
    context.read<DashboardCubit>().load();
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: _start, end: _end),
    );
    if (picked != null) {
      setState(() {
        _start = DateTime(picked.start.year, picked.start.month, picked.start.day);
        _end = DateTime(picked.end.year, picked.end.month, picked.end.day);
      });
    }
  }

  Future<void> _exportReport({
    required RevenueSummary summary,
    required List<ClientRevenue> top,
    required double tax,
    required List<({InvoiceStatus status, int count})> breakdown,
  }) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final svc = const ReportPdfService();
      final bytes = await svc.build(
        summary: summary,
        topClients: top,
        totalTax: tax,
        start: _start,
        end: _end,
        breakdown: breakdown,
      );
      await svc.share(bytes);
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not export: $e')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Reports',
      refreshable: true,
      onRefresh: () => context.read<DashboardCubit>().load(),
      actions: [
        IconButton(
          tooltip: 'Pick date range',
          icon: const Icon(HugeIconsStroke.calendar01, size: 18),
          onPressed: _pickRange,
        ),
      ],
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state.loading && state.summary == null) {
            return ListView(
              children: const [
                SizedBox(height: 120),
                Center(child: CircularProgressIndicator()),
              ],
            );
          }
          if (state.summary == null) {
            return ListView(
              children: const [
                SizedBox(height: 32),
                EmptyState(
                  icon: Icons.bar_chart_rounded,
                  title: 'No data yet',
                  subtitle: 'Create a few invoices to see your reports.',
                ),
              ],
            );
          }
          final inRange = state.recentInvoices
              .where(
                (i) =>
                    !i.issueDate.isBefore(_start) &&
                    !i.issueDate.isAfter(
                      _end.add(const Duration(days: 1)),
                    ),
              )
              .toList();
          final calc = const ReportsCalculator();
          final summary = calc.summarize(inRange, DateTime.now());
          final trend = calc.monthlyTrend(inRange);
          final top = calc.topClients(
            invoices: inRange,
            clientsById: state.clientsById,
            limit: 5,
          );
          final tax = calc.totalTaxCollected(inRange);
          final breakdownMap = calc.statusBreakdown(inRange);
          final breakdown = breakdownMap.entries.map((e) => (status: e.key, count: e.value.round())).toList();
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppCard(
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: context.colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '${Formatters.date(_start)} — ${Formatters.date(_end)}  ·  ${inRange.length} invoice${inRange.length == 1 ? '' : 's'}',
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _pickRange,
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ),
              ),
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
                      summary.totalRevenue,
                      code: 'USD',
                    ),
                    icon: Icons.payments_outlined,
                    color: AppColors.success,
                  ),
                  MetricCard(
                    label: 'Outstanding',
                    value: Formatters.currency(
                      summary.outstanding,
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
                    value: Formatters.number(summary.totalCount),
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
              _StatusBreakdown(breakdown: breakdownMap),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Export & share PDF',
                icon: Icons.ios_share_rounded,
                loading: _exporting,
                onPressed: _exporting
                    ? null
                    : () => _exportReport(
                        summary: summary,
                        top: top,
                        tax: tax,
                        breakdown: breakdown,
                      ),
              ),
              const SizedBox(height: AppSpacing.lg),
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
                    e.key.label,
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
