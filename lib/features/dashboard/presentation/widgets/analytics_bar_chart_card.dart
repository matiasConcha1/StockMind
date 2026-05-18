import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:stockmind/core/theme/app_theme.dart';
import 'package:stockmind/core/widgets/empty_state.dart';
import 'package:stockmind/core/widgets/section_card.dart';
import 'package:stockmind/features/dashboard/analytics/models/dashboard_analytics_snapshot.dart';

class AnalyticsBarChartCard extends StatelessWidget {
  const AnalyticsBarChartCard({
    required this.title,
    required this.subtitle,
    required this.points,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<AnalyticsSeriesPoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxY = points.isEmpty
        ? 10.0
        : points
                .map((item) => item.value > item.secondaryValue ? item.value : item.secondaryValue)
                .reduce((a, b) => a > b ? a : b) +
            4;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(subtitle, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          if (points.isEmpty)
            const SizedBox(
              height: 260,
              child: EmptyState(
                title: 'Sin comparativas aún',
                subtitle: 'Las entradas y salidas aparecerán aquí cuando haya movimiento real.',
                icon: Icons.bar_chart_rounded,
                compact: true,
              ),
            )
          else
            Column(
              children: [
                SizedBox(
                  height: 260,
                  child: BarChart(
                    BarChartData(
                      minY: 0,
                      maxY: maxY,
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: theme.colorScheme.outlineVariant,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(),
                        rightTitles: const AxisTitles(),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= points.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  points[index].label,
                                  style: theme.textTheme.bodySmall,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: points.asMap().entries.map((entry) {
                        final item = entry.value;
                        return BarChartGroupData(
                          x: entry.key,
                          barsSpace: 6,
                          barRods: [
                            BarChartRodData(
                              toY: item.value,
                              width: 12,
                              borderRadius: BorderRadius.circular(8),
                              color: AppTheme.success,
                            ),
                            BarChartRodData(
                              toY: item.secondaryValue,
                              width: 12,
                              borderRadius: BorderRadius.circular(8),
                              color: AppTheme.warning,
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 14,
                  runSpacing: 10,
                  children: const [
                    _LegendPill(
                      label: 'Entradas',
                      color: AppTheme.success,
                    ),
                    _LegendPill(
                      label: 'Salidas',
                      color: AppTheme.warning,
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LegendPill extends StatelessWidget {
  const _LegendPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
