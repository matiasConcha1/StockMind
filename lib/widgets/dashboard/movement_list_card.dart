import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stockmind/models/inventory_movement.dart';
import 'package:stockmind/widgets/common/section_card.dart';

class MovementListCard extends StatelessWidget {
  const MovementListCard({super.key, required this.movements});

  final List<InventoryMovement> movements;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('dd/MM HH:mm');

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Últimos movimientos', style: theme.textTheme.titleLarge),
          const SizedBox(height: 18),
          if (movements.isEmpty)
            Text(
              'Todavía no hay movimientos registrados.',
              style: theme.textTheme.bodyMedium,
            )
          else
            ...movements.map(
              (movement) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _colorForType(movement.type)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _iconForType(movement.type),
                        color: _colorForType(movement.type),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(movement.title,
                              style: theme.textTheme.titleMedium),
                          Text(
                            '${movement.productName} · ${movement.quantity} unidades',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatter.format(movement.timestamp),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
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

  Color _colorForType(MovementType type) {
    switch (type) {
      case MovementType.created:
        return const Color(0xFF1D4ED8);
      case MovementType.updated:
        return const Color(0xFF0F766E);
      case MovementType.deleted:
        return const Color(0xFFDC2626);
    }
  }

  IconData _iconForType(MovementType type) {
    switch (type) {
      case MovementType.created:
        return Icons.add_box_rounded;
      case MovementType.updated:
        return Icons.sync_alt_rounded;
      case MovementType.deleted:
        return Icons.delete_forever_rounded;
    }
  }
}
