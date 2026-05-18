import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stockmind/core/widgets/empty_state.dart';
import 'package:stockmind/core/widgets/section_card.dart';
import 'package:stockmind/features/dashboard/analytics/models/dashboard_analytics_snapshot.dart';

class ActivityFeedCard extends StatelessWidget {
  const ActivityFeedCard({
    required this.items,
    super.key,
  });

  final List<ActivityInsightItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Activity insights', style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Eventos importantes del workspace agrupados por prioridad operativa.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          if (items.isEmpty)
            const SizedBox(
              height: 240,
              child: EmptyState(
                title: 'Sin actividad todavía',
                subtitle:
                    'Cuando haya movimientos, alertas o solicitudes, verás aquí el pulso operativo.',
                icon: Icons.timeline_rounded,
                compact: true,
              ),
            )
          else
            Column(
              children: items
                  .take(6)
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _FeedTile(item: item),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _FeedTile extends StatelessWidget {
  const _FeedTile({required this.item});

  final ActivityInsightItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('dd/MM · HH:mm');
    final accent = _accentFor(item.priority, theme.colorScheme);
    final icon = _iconFor(item.kind);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _PriorityPill(priority: item.priority),
                  ],
                ),
                const SizedBox(height: 4),
                Text(item.subtitle, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text(
                  formatter.format(item.when),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _accentFor(ActivityInsightPriority priority, ColorScheme colorScheme) {
    switch (priority) {
      case ActivityInsightPriority.high:
        return colorScheme.error;
      case ActivityInsightPriority.medium:
        return const Color(0xFFF59E0B);
      case ActivityInsightPriority.low:
        return colorScheme.primary;
    }
  }

  IconData _iconFor(ActivityInsightKind kind) {
    switch (kind) {
      case ActivityInsightKind.movement:
        return Icons.swap_horiz_rounded;
      case ActivityInsightKind.alert:
        return Icons.notifications_active_outlined;
      case ActivityInsightKind.request:
        return Icons.inventory_outlined;
      case ActivityInsightKind.product:
        return Icons.inventory_2_outlined;
    }
  }
}

class _PriorityPill extends StatelessWidget {
  const _PriorityPill({required this.priority});

  final ActivityInsightPriority priority;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = switch (priority) {
      ActivityInsightPriority.high => colorScheme.error,
      ActivityInsightPriority.medium => const Color(0xFFF59E0B),
      ActivityInsightPriority.low => colorScheme.primary,
    };
    final label = switch (priority) {
      ActivityInsightPriority.high => 'Alta',
      ActivityInsightPriority.medium => 'Media',
      ActivityInsightPriority.low => 'Info',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}
