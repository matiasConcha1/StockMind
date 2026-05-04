import 'package:flutter/material.dart';
import 'package:stockmind/models/product.dart';
import 'package:stockmind/widgets/common/section_card.dart';

class LowStockAlertCard extends StatelessWidget {
  const LowStockAlertCard({super.key, required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active_rounded,
                  color: Color(0xFFF59E0B)),
              const SizedBox(width: 10),
              Text('Alertas de stock', style: theme.textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 16),
          if (products.isEmpty)
            Text(
              'Todo el inventario está sobre el mínimo configurado.',
              style: theme.textTheme.bodyMedium,
            )
          else
            ...products.map(
              (product) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFF59E0B)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name,
                              style: theme.textTheme.titleMedium),
                          Text(
                            'Quedan ${product.quantity} unidades · mínimo ${product.minimumStock}',
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
    );
  }
}
