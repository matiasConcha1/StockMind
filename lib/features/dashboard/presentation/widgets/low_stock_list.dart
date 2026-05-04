import 'package:flutter/material.dart';
import 'package:stockmind/models/product.dart';

class LowStockList extends StatelessWidget {
  const LowStockList({
    required this.products,
    super.key,
  });

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('No hay alertas activas.'),
              )
            else
              ...products.map(
                (product) => Container(
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
                          color: Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.name, style: theme.textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(
                              'Stock actual ${product.stock} · mínimo ${product.minimumStock}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
