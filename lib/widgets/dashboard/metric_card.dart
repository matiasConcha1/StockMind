import 'package:flutter/material.dart';
import 'package:stockmind/models/dashboard_metric.dart';
import 'package:stockmind/widgets/common/section_card.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({super.key, required this.metric});

  final DashboardMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: metric.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(metric.icon, color: metric.color),
          ),
          const Spacer(),
          Text(metric.title, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(metric.value, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            metric.subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
