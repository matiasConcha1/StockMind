import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:stockmind/core/theme/app_theme.dart';
import 'package:stockmind/core/widgets/empty_state.dart';
import 'package:stockmind/core/widgets/section_card.dart';
import 'package:stockmind/features/dashboard/analytics/models/dashboard_analytics_snapshot.dart';

class AnalyticsDonutChartCard extends StatelessWidget {
  const AnalyticsDonutChartCard({
    required this.title,
    required this.subtitle,
    required this.items,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<AnalyticsBreakdownItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = [
      AppTheme.brand,
      AppTheme.brandViolet,
      AppTheme.success,
      const Color(0xFFF97316),
      const Color(0xFF38BDF8),
    ];
    final total = items.fold<double>(0, (sum, item) => sum + item.value);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(subtitle, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          if (items.isEmpty)
            const SizedBox(
              height: 250,
              child: EmptyState(
                title: 'Sin distribución disponible',
                subtitle: 'Agrega más datos operativos para desbloquear esta vista.',
                icon: Icons.pie_chart_outline_rounded,
                compact: true,
              ),
            )
          else ...[
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 68,
                  sectionsSpace: 3,
                  sections: items.asMap().entries.map((entry) {
                    final item = entry.value;
                    return PieChartSectionData(
                      value: item.value,
                      color: palette[entry.key % palette.length],
                      title: total == 0
                          ? '0%'
                          : '${((item.value / total) * 100).round()}%',
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
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: items.asMap().entries.map((entry) {
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
                          color: palette[entry.key % palette.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.subtitle == null
                            ? item.label
                            : '${item.label} · ${item.subtitle}',
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
