import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:stockmind/core/widgets/section_card.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    required this.label,
    required this.value,
    required this.helper,
    required this.icon,
    required this.color,
    this.trend,
    super.key,
  });

  final String label;
  final String value;
  final String helper;
  final IconData icon;
  final Color color;
  final String? trend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 768;
    final isSmallPhone = width < 480;

    return SectionCard(
      padding: EdgeInsets.all(isSmallPhone ? 16 : isMobile ? 18 : 24),
      borderRadius: isMobile ? 24 : 28,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: isSmallPhone ? 120 : isMobile ? 150 : 210),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: isSmallPhone ? 42 : isMobile ? 50 : 52,
                  height: isSmallPhone ? 42 : isMobile ? 50 : 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.18),
                        color.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(isMobile ? 15 : 16),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: isSmallPhone ? 22 : isMobile ? 22 : 24,
                  ),
                ),
                const Spacer(),
                if (trend != null)
                  Flexible(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallPhone ? 8 : 10,
                        vertical: isSmallPhone ? 5 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        trend!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: isSmallPhone ? 12 : null,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: isSmallPhone ? 10 : isMobile ? 14 : 18),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (isMobile
                      ? theme.textTheme.titleMedium
                      : theme.textTheme.bodyMedium)
                  ?.copyWith(fontSize: isSmallPhone ? 17 : null),
            ),
            SizedBox(height: isSmallPhone ? 4 : isMobile ? 6 : 8),
            Text(
              value,
              style: (isMobile
                      ? theme.textTheme.headlineSmall
                      : theme.textTheme.headlineMedium)
                  ?.copyWith(fontSize: isSmallPhone ? 30 : null),
            ),
            SizedBox(height: isSmallPhone ? 3 : isMobile ? 4 : 6),
            Text(
              helper,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: isSmallPhone ? 13 : null,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.08, end: 0);
  }
}
