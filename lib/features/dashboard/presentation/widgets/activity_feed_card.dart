import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stockmind/core/widgets/empty_state.dart';
import 'package:stockmind/core/widgets/section_card.dart';
import 'package:stockmind/features/alerts/data/models/stock_alert.dart';
import 'package:stockmind/features/dashboard/data/models/stock_movement.dart';
import 'package:stockmind/features/products/models/product.dart';

class ActivityFeedCard extends StatelessWidget {
  const ActivityFeedCard({
    required this.movements,
    required this.alerts,
    required this.criticalProducts,
    super.key,
  });

  final List<StockMovement> movements;
  final List<StockAlert> alerts;
  final List<Product> criticalProducts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <_FeedItem>[
      ...movements.take(3).map(_FeedItem.fromMovement),
      ...alerts.take(3).map(_FeedItem.fromAlert),
      ...criticalProducts.take(3).map(_FeedItem.fromProduct),
    ]..sort((a, b) => b.when.compareTo(a.when));

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Activity feed', style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Movimientos recientes, alertas activas y productos críticos en una sola línea de tiempo.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          if (items.isEmpty)
            const SizedBox(
              height: 220,
              child: EmptyState(
                title: 'Sin actividad reciente',
                subtitle:
                    'Cuando el inventario tenga movimientos o alertas, verás aquí el pulso operativo.',
                icon: Icons.timeline_rounded,
                compact: true,
              ),
            )
          else
            Column(
              children: items
                  .take(6)
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _FeedTile(item: item),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _FeedTile extends StatelessWidget {
  const _FeedTile({required this.item});

  final _FeedItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('dd/MM · HH:mm');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(item.subtitle, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatter.format(item.when),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _FeedItem {
  const _FeedItem({
    required this.title,
    required this.subtitle,
    required this.when,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final DateTime when;
  final IconData icon;
  final Color color;

  factory _FeedItem.fromMovement(StockMovement movement) {
    return _FeedItem(
      title: movement.productName,
      subtitle:
          '${movement.type.toUpperCase()} · ${movement.quantity} unid. · ${movement.reason}',
      when: movement.createdAt,
      icon: movement.isEntry
          ? Icons.south_west_rounded
          : movement.isExit
              ? Icons.north_east_rounded
              : Icons.swap_horiz_rounded,
      color: movement.isEntry
          ? Colors.green
          : movement.isExit
              ? Colors.redAccent
              : Colors.amber.shade700,
    );
  }

  factory _FeedItem.fromAlert(StockAlert alert) {
    return _FeedItem(
      title: alert.title,
      subtitle: '${alert.productName} · ${alert.message}',
      when: alert.updatedAt,
      icon: Icons.notifications_active_outlined,
      color: alert.isHigh
          ? Colors.redAccent
          : alert.isMedium
              ? Colors.orangeAccent
              : Colors.blueAccent,
    );
  }

  factory _FeedItem.fromProduct(Product product) {
    return _FeedItem(
      title: 'Stock crítico',
      subtitle: '${product.name} · ${product.totalStock} unid. disponibles',
      when: product.updatedAt,
      icon: Icons.inventory_2_outlined,
      color: Colors.deepOrangeAccent,
    );
  }
}
