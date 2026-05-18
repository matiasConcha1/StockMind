import 'package:flutter/material.dart';
import 'package:stockmind/core/widgets/section_card.dart';

class AnalyticsKpiCard extends StatefulWidget {
  const AnalyticsKpiCard({
    required this.label,
    required this.value,
    required this.helper,
    required this.icon,
    required this.accent,
    this.trendLabel,
    this.isCurrency = false,
    super.key,
  });

  final String label;
  final num value;
  final String helper;
  final IconData icon;
  final Color accent;
  final String? trendLabel;
  final bool isCurrency;

  @override
  State<AnalyticsKpiCard> createState() => _AnalyticsKpiCardState();
}

class _AnalyticsKpiCardState extends State<AnalyticsKpiCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.01 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: SectionCard(
          gradient: LinearGradient(
            colors: [
              widget.accent.withValues(alpha: 0.14),
              theme.colorScheme.surface.withValues(alpha: 0.96),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: widget.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(widget.icon, color: widget.accent),
                  ),
                  const Spacer(),
                  if (widget.trendLabel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Text(
                        widget.trendLabel!,
                        style: theme.textTheme.labelMedium,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                widget.label,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: widget.value.toDouble()),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  final display = widget.isCurrency
                      ? '\$${value.toStringAsFixed(0)}'
                      : widget.value is int
                          ? value.round().toString()
                          : value.toStringAsFixed(1);
                  return Text(
                    display,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      letterSpacing: -0.9,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                widget.helper,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
