import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stockmind/core/theme/app_theme.dart';
import 'package:stockmind/models/dashboard_snapshot.dart';

class CategoryChartCard extends StatelessWidget {
  const CategoryChartCard({
    required this.categories,
    super.key,
  });

  final List<CategorySlice> categories;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$');
    final theme = Theme.of(context);
    final total = categories.fold<double>(0, (sum, item) => sum + item.value);
    final palette = [
      AppTheme.brand,
      const Color(0xFF0EA5E9),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Valor por categoría', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text('Distribución del valor total del inventario.', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            if (categories.isEmpty)
              const SizedBox(
                height: 250,
                child: Center(child: Text('No hay categorías para mostrar.')),
              )
            else
              SizedBox(
                height: 250,
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 70,
                    sectionsSpace: 3,
                    sections: categories.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return PieChartSectionData(
                        value: item.value,
                        color: palette[index % palette.length],
                        title: '${((item.value / total) * 100).round()}%',
                        radius: 58,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: categories.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: palette[index % palette.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${item.label} · ${currency.format(item.value)}'),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
