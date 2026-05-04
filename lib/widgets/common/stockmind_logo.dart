import 'package:flutter/material.dart';

class StockMindLogo extends StatelessWidget {
  const StockMindLogo({
    super.key,
    this.showSubtitle = true,
    this.compact = false,
    this.bright = false,
  });

  final bool showSubtitle;
  final bool compact;
  final bool bright;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryTextColor = bright ? Colors.white : null;
    final secondaryTextColor =
        bright ? const Color(0xFFBFDBFE) : theme.colorScheme.onSurfaceVariant;
    final logoSize = compact ? 40.0 : 48.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 14 : 18),
            gradient: const LinearGradient(
              colors: [Color(0xFF1D4ED8), Color(0xFF60A5FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x332563EB),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Icon(
            Icons.auto_graph_rounded,
            color: Colors.white,
            size: compact ? 22 : 26,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'StockMind',
              style: theme.textTheme.titleLarge?.copyWith(
                color: primaryTextColor,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            if (showSubtitle)
              Text(
                'Inventario inteligente',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: secondaryTextColor,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
