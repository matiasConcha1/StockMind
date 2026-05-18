import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:stockmind/core/theme/app_theme.dart';
import 'package:stockmind/core/widgets/empty_state.dart';
import 'package:stockmind/core/widgets/section_card.dart';
import 'package:stockmind/features/dashboard/analytics/models/dashboard_analytics_snapshot.dart';

class AnalyticsLineChartCard extends StatelessWidget {
  const AnalyticsLineChartCard({
    required this.title,
    required this.subtitle,
    required this.points,
    this.accent = AppTheme.brand,
    this.superTitle,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<AnalyticsSeriesPoint> points;
  final Color accent;
  final String? superTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxY = points.isEmpty
        ? 10.0
        : points
                .map((item) => item.value.abs())
                .reduce((a, b) => a > b ? a : b) +
            4;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (superTitle != null) ...[
            Text(superTitle!, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
          ],
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 22),
          if (points.isEmpty)
            const SizedBox(
              height: 260,
              child: EmptyState(
                title: 'Sin datos para graficar',
                subtitle: 'Cuando existan movimientos en el rango elegido, verás la tendencia aquí.',
                icon: Icons.show_chart_rounded,
                compact: true,
              ),
            )
          else
            SizedBox(
              height: 260,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (points.length - 1).toDouble(),
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
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => theme.colorScheme.surface,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: maxY <= 20 ? 5 : null,
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
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: accent,
                      barWidth: 4,
                      spots: points.asMap().entries
                          .map((entry) => FlSpot(entry.key.toDouble(), entry.value.value))
                          .toList(),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4.2,
                            color: accent,
                            strokeWidth: 2,
                            strokeColor: theme.colorScheme.surface,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            accent.withValues(alpha: 0.24),
                            accent.withValues(alpha: 0.02),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
