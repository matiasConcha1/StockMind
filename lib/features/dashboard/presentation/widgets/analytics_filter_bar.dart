import 'package:flutter/material.dart';
import 'package:stockmind/features/dashboard/analytics/models/dashboard_analytics_snapshot.dart';

class AnalyticsFilterBar extends StatelessWidget {
  const AnalyticsFilterBar({
    required this.selectedRange,
    required this.onRangeChanged,
    super.key,
  });

  final AnalyticsTimeRange selectedRange;
  final ValueChanged<AnalyticsTimeRange> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 720;
    final chips = AnalyticsTimeRange.values
        .map(
          (range) => ChoiceChip(
            label: Text(range.label),
            selected: range == selectedRange,
            onSelected: (_) => onRangeChanged(range),
          ),
        )
        .toList();
    if (isCompact) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < chips.length; i++) ...[
              chips[i],
              if (i != chips.length - 1) const SizedBox(width: 10),
            ],
          ],
        ),
      );
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: chips,
    );
  }
}
