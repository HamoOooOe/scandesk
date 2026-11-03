import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/legend.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/punch_ring.dart';
import '../../../../core/widgets/tag_card.dart';
import '../../../tickets/domain/ticket.dart';
import '../../../tickets/presentation/widgets/ticket_style.dart';
import '../cubit/dashboard_cubit.dart';

/// Manager overview: where tickets are, how the week went, and which
/// devices keep coming back.
class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DashboardCubit>()..start(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state.loading) return const LoadingView();
        if (state.error != null) return ErrorView(message: state.error);
        final data = state.data;
        // Scale the bars to the work still in flight, so a long history of
        // resolved tickets does not squash the open ones into slivers.
        final maxStatus = [
          TicketStatus.open,
          TicketStatus.assigned,
          TicketStatus.inProgress,
        ].fold<int>(1, (a, s) => (data.byStatus[s] ?? 0) > a ? data.byStatus[s]! : a);
        final avg = data.avgResolutionHours;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Legend(l10n.flowTitle),
            const SizedBox(height: 8),
            TagCard(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                children: [
                  for (final status in TicketStatus.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 104,
                            child: Text(status.label(l10n), style: theme.textTheme.titleMedium),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(
                                  end: ((data.byStatus[status] ?? 0) / maxStatus).clamp(0.0, 1.0),
                                ),
                                duration: const Duration(milliseconds: 700),
                                curve: Curves.easeOutCubic,
                                builder: (context, v, _) => LinearProgressIndicator(
                                  value: v,
                                  minHeight: 12,
                                  color: status.color,
                                  backgroundColor: scheme.surfaceContainerHigh,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            child: Text(
                              '${data.byStatus[status] ?? 0}',
                              textAlign: TextAlign.end,
                              style: AppTheme.mono(context, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Divider(),
                  const SizedBox(height: 4),
                  _FactRow(l10n.openNow, '${data.openNow}'),
                  _FactRow(l10n.overdueLabel, '${data.overdue}', alert: data.overdue > 0),
                  _FactRow(
                    l10n.avgResolve,
                    avg == null ? '—' : l10n.hoursShort(avg.toStringAsFixed(1)),
                  ),
                  _FactRow(l10n.devicesInRepair, '${data.assetsInRepair} / ${data.totalAssets}'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Legend(l10n.reportsWeek),
            const SizedBox(height: 8),
            TagCard(
              hole: false,
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
              child: SizedBox(height: 150, child: _WeekChart(days: data.reportsPerDay)),
            ),
            const SizedBox(height: 24),
            Legend(l10n.mostRepaired),
            const SizedBox(height: 8),
            if (data.mostRepaired.isEmpty)
              Text(l10n.noData, style: theme.textTheme.bodyMedium)
            else
              for (final r in data.mostRepaired)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TagCard(
                    onTap: () => context.push(Routes.assetPath(r.asset.id)),
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Row(
                      children: [
                        PunchRing(punchedMonths: r.punchedMonths, size: 52, currentMonth: DateTime.now().month),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.asset.code, style: AppTheme.mono(context, size: 12)),
                              Text(r.asset.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 14),
                          child: Text(
                            l10n.ticketsCount(r.count),
                            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow(this.label, this.value, {this.alert = false});

  final String label;
  final String value;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            value,
            style: AppTheme.mono(context, size: 14).copyWith(
              color: alert ? theme.colorScheme.tertiary : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.days});

  final List<({DateTime day, int count})> days;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final top = days.fold<int>(1, (a, d) => d.count > a ? d.count : a);

    return BarChart(
      BarChartData(
        maxY: top + 2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        // Touch is off; the "tooltips" are just the count printed above
        // each bar, with no box around them.
        barTouchData: BarTouchData(
          enabled: false,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.transparent,
            tooltipPadding: EdgeInsets.zero,
            tooltipMargin: 4,
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
              '${rod.toY.toInt()}',
              AppTheme.mono(context, size: 12),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  DateFormat.E(locale).format(days[value.toInt()].day),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < days.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: days[i].count.toDouble(),
                  width: 22,
                  color: i == days.length - 1 ? scheme.primary : scheme.primary.withValues(alpha: 0.45),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                ),
              ],
              showingTooltipIndicators: days[i].count > 0 ? [0] : [],
            ),
        ],
      ),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }
}
