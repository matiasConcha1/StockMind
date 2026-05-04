import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stockmind/core/widgets/empty_state.dart';
import 'package:stockmind/core/widgets/section_card.dart';
import 'package:stockmind/features/dashboard/data/models/stock_movement.dart';

class RecentStockMovementsCard extends StatelessWidget {
  const RecentStockMovementsCard({
    required this.movements,
    super.key,
  });

  final List<StockMovement> movements;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('dd MMM, HH:mm');

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Últimos movimientos', style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Historial reciente de entradas y salidas de stock.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          if (movements.isEmpty)
            const SizedBox(
              height: 280,
              child: EmptyState(
                title: 'Sin movimientos todavía',
                subtitle:
                    'Cuando actualices stock en tus productos, verás aquí el historial reciente.',
                icon: Icons.swap_horiz_rounded,
              ),
            )
          else
            Column(
              children: movements
                  .map(
                    (movement) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          _MovementTypeBadge(type: movement.type),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  movement.productName,
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  movement.hasLocationContext
                                      ? '${movement.locationName} · ${movement.reason}'
                                      : movement.reason,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${movement.isEntry ? '+' : '-'}${movement.quantity}',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${movement.previousTotalStock} → ${movement.newTotalStock}',
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatter.format(movement.createdAt),
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _MovementTypeBadge extends StatelessWidget {
  const _MovementTypeBadge({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final isEntry = type == 'entrada';
    final color = isEntry ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        isEntry ? 'Entrada' : 'Salida',
        style: TextStyle(
          color: color.shade700,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
