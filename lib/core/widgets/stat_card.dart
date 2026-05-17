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
      interactive: true,
      padding: EdgeInsets.all(isSmallPhone ? 16 : isMobile ? 18 : 22),
      borderRadius: isMobile ? 24 : 28,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: isSmallPhone ? 124 : isMobile ? 150 : 194,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: isSmallPhone ? 46 : isMobile ? 52 : 56,
                  height: isSmallPhone ? 46 : isMobile ? 52 : 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.22),
                        color.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(isMobile ? 16 : 18),
                    border: Border.all(color: color.withValues(alpha: 0.16)),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: isSmallPhone ? 22 : isMobile ? 23 : 24,
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
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: color.withValues(alpha: 0.12)),
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
            SizedBox(height: isSmallPhone ? 14 : isMobile ? 16 : 20),
            Text(
              label,
              maxLines: isMobile ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: (isMobile
                      ? theme.textTheme.titleMedium
                      : theme.textTheme.bodyMedium)
                  ?.copyWith(
                    fontSize: isSmallPhone ? 17 : null,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: isSmallPhone ? 6 : isMobile ? 8 : 10),
            Text(
              value,
              style: (isMobile
                      ? theme.textTheme.headlineSmall
                      : theme.textTheme.headlineMedium)
                  ?.copyWith(
                    fontSize: isSmallPhone ? 30 : null,
                    letterSpacing: -0.9,
                  ),
            ),
            SizedBox(height: isSmallPhone ? 6 : isMobile ? 7 : 10),
            Text(
              helper,
              maxLines: isSmallPhone ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: isSmallPhone ? 13 : null,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.08, end: 0);
  }
}
