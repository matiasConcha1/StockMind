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
    final criticalRisk = product.isExpired || status.isOutOfStock;
    final warningRisk =
        !criticalRisk &&
        (product.isExpiringSoon || product.totalStock <= product.minStock);
    final foreground = product.isOptimal
        ? const Color(0xFF16A34A)
        : criticalRisk
            ? colorScheme.error
            : warningRisk
                ? const Color(0xFFF59E0B)
                : const Color(0xFFF97316);
    final background = foreground.withValues(alpha: 0.14);
    final icon = product.isOptimal
        ? Icons.check_circle_rounded
        : criticalRisk
            ? Icons.error_outline_rounded
            : Icons.warning_amber_rounded;
    final label = product.operationalStatusLabel;

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
