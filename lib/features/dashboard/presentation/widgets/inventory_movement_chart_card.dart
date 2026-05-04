import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:stockmind/core/theme/app_theme.dart';
import 'package:stockmind/core/widgets/empty_state.dart';
import 'package:stockmind/core/widgets/section_card.dart';

class InventoryMovementPoint {
  const InventoryMovementPoint({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;
}

class InventoryMovementChartCard extends StatelessWidget {
  const InventoryMovementChartCard({
    required this.points,
    super.key,
  });

  final List<InventoryMovementPoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Movimiento de inventario', style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Evolución reciente de unidades gestionadas por movimientos reales.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          if (points.isEmpty)
            const SizedBox(
              height: 280,
              child: EmptyState(
                title: 'Sin actividad reciente',
                subtitle:
                    'Aún no hay movimientos suficientes para graficar el comportamiento del stock.',
                icon: Icons.show_chart_rounded,
              ),
            )
          else
            SizedBox(
              height: 280,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (points.length - 1).toDouble(),
                  minY: 0,
                  maxY: points
                          .map((point) => point.value)
                          .reduce((a, b) => a > b ? a : b) +
                      12,
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: 10,
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
                      sideTitles: SideTitles(showTitles: true, reservedSize: 34),
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
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => theme.colorScheme.surface,
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: AppTheme.brand,
                      barWidth: 4,
                      spots: points.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.value);
                      }).toList(),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4.5,
                            color: AppTheme.brand,
                            strokeWidth: 2,
                            strokeColor: theme.colorScheme.surface,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.brand.withValues(alpha: 0.24),
                            AppTheme.brandViolet.withValues(alpha: 0.04),
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
