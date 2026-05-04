import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:stockmind/core/theme/app_theme.dart';
import 'package:stockmind/core/widgets/empty_state.dart';
import 'package:stockmind/core/widgets/section_card.dart';
import 'package:stockmind/features/products/models/product.dart';

class StockBarChartCard extends StatelessWidget {
  const StockBarChartCard({
    required this.products,
    super.key,
  });

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stock por producto', style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Lectura rápida de disponibilidad actual por SKU líder.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          if (products.isEmpty)
            const SizedBox(
              height: 280,
              child: EmptyState(
                title: 'Sin productos',
                subtitle: 'Agrega productos para ver su comportamiento de stock.',
                icon: Icons.inventory_2_rounded,
              ),
            )
          else
            SizedBox(
              height: 280,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: 10,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: theme.colorScheme.outlineVariant,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 36),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= products.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              products[index].name.split(' ').first,
                              style: theme.textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: products.asMap().entries.map((entry) {
                    final index = entry.key;
                    final product = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: product.stock.toDouble(),
                          borderRadius: BorderRadius.circular(8),
                          width: 22,
                          gradient: LinearGradient(
                            colors: product.isLowStock
                                ? [
                                    AppTheme.warning,
                                    AppTheme.warning.withValues(alpha: 0.55),
                                  ]
                                : [
                                    AppTheme.brand,
                                    AppTheme.brandViolet,
                                  ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
