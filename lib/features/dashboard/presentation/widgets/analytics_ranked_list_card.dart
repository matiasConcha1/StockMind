import 'package:flutter/material.dart';
import 'package:stockmind/core/widgets/empty_state.dart';
import 'package:stockmind/core/widgets/section_card.dart';
import 'package:stockmind/features/dashboard/analytics/models/dashboard_analytics_snapshot.dart';

class AnalyticsRankedListCard extends StatelessWidget {
  const AnalyticsRankedListCard({
    required this.title,
    required this.subtitle,
    required this.items,
    this.emptyTitle = 'Sin datos aún',
    this.emptySubtitle = 'Esta lista se llenará cuando exista actividad suficiente.',
    super.key,
  });

  final String title;
  final String subtitle;
  final List<AnalyticsBreakdownItem> items;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxValue = items.isEmpty
        ? 1.0
        : items.map((item) => item.value).reduce((a, b) => a > b ? a : b);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(subtitle, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 22),
          if (items.isEmpty)
            SizedBox(
              height: 260,
              child: EmptyState(
                title: emptyTitle,
                subtitle: emptySubtitle,
                icon: Icons.insights_outlined,
                compact: true,
              ),
            )
          else
            Column(
              children: items.take(5).toList().asMap().entries.map((entry) {
                final item = entry.value;
                final progress = maxValue == 0 ? 0.0 : item.value / maxValue;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('${entry.key + 1}'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium,
                                ),
                                if (item.subtitle != null) ...[
                                  const SizedBox(height: 4),
                                  Text(item.subtitle!, style: theme.textTheme.bodySmall),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item.value.toStringAsFixed(0),
                            style: theme.textTheme.labelLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          value: progress,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.28),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
