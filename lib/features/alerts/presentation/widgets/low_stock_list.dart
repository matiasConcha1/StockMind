import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:stockmind/core/widgets/empty_state.dart';
import 'package:stockmind/core/widgets/section_card.dart';
import 'package:stockmind/features/products/models/product.dart';

class LowStockList extends StatelessWidget {
  const LowStockList({
    required this.products,
    super.key,
  });

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Alertas de reposición', style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Productos que ya alcanzaron o superaron el mínimo definido.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          if (products.isEmpty)
            const SizedBox(
              height: 260,
              child: EmptyState(
                title: 'Inventario saludable',
                subtitle: 'No hay alertas activas en este momento.',
                icon: Icons.verified_rounded,
              ),
            )
          else
            ...products.asMap().entries.map(
              (entry) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _priorityColor(products[entry.key]).withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        products[entry.key].isCriticalStock
                            ? Icons.report_gmailerrorred_rounded
                            : Icons.warning_amber_rounded,
                        color: _priorityColor(products[entry.key]),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            products[entry.key].name,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Stock actual ${products[entry.key].stock} · mínimo ${products[entry.key].minStock}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _PriorityBadge(product: products[entry.key]),
                  ],
                ),
              ).animate().fadeIn(
                    duration: 260.ms,
                    delay: (entry.key * 40).ms,
                  ),
            ),
        ],
      ),
    );
  }

  Color _priorityColor(Product product) {
    return product.isCriticalStock ? const Color(0xFFEF4444) : Colors.orange;
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final color = product.isCriticalStock
        ? const Color(0xFFEF4444)
        : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        product.isCriticalStock ? 'Crítico' : 'Bajo',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
