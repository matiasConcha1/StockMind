import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    required this.label,
    required this.value,
    required this.helper,
    required this.icon,
    required this.color,
    super.key,
  });

  final String label;
  final String value;
  final String helper;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color),
            ),
            const Spacer(),
            Text(label, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(helper, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
