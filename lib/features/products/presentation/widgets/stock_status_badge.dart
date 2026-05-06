import 'package:flutter/material.dart';
import 'package:stockmind/features/products/models/product.dart';

class StockStatusBadge extends StatelessWidget {
  const StockStatusBadge({
    required this.product,
    this.compact = false,
    super.key,
  });

  final Product product;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = product.stockStatus;
    final isExpired = product.isExpired;
    final foreground = isExpired
        ? colorScheme.error
        : status.foregroundColor(colorScheme);
    final background = isExpired
        ? colorScheme.error.withValues(alpha: 0.12)
        : status.backgroundColor(colorScheme);
    final icon = isExpired ? Icons.event_busy_outlined : status.icon;
    final label = isExpired ? 'Vencido' : status.label;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 14 : 16, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
