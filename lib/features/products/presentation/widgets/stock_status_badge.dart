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
    final status = product.stockStatus;
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = status.foregroundColor(colorScheme);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: status.backgroundColor(colorScheme),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: compact ? 14 : 16, color: foreground),
          const SizedBox(width: 6),
          Text(
            status.label,
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
