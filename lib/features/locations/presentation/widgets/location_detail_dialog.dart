import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stockmind/core/widgets/empty_state.dart';
import 'package:stockmind/features/locations/providers/locations_provider.dart';
import 'package:stockmind/features/products/models/product.dart';

class LocationDetailDialog extends StatelessWidget {
  const LocationDetailDialog({
    required this.snapshot,
    super.key,
  });

  final LocationInventorySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(symbol: '\$');

    return AlertDialog(
      title: Text(snapshot.location.name),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                snapshot.location.description.isEmpty
                    ? 'Sin descripción adicional.'
                    : snapshot.location.description,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetricChip(
                    label: 'Productos',
                    value: snapshot.products.length.toString(),
                  ),
                  _MetricChip(
                    label: 'Unidades',
                    value: snapshot.totalUnits.toString(),
                  ),
                  _MetricChip(
                    label: 'Tipo',
                    value: _capitalize(snapshot.location.type),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (snapshot.products.isEmpty)
                const SizedBox(
                  height: 220,
                  child: EmptyState(
                    title: 'Ubicación vacía',
                    subtitle:
                        'Todavía no hay productos asignados a esta ubicación.',
                    icon: Icons.inventory_2_outlined,
                  ),
                )
              else
                Column(
                  children: snapshot.products
                      .map(
                        (product) => _LocationProductRow(
                          product: product,
                          quantity: product.locationQuantities[snapshot.location.id]
                                  ?.quantity ??
                              0,
                          currency: currency,
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _LocationProductRow extends StatelessWidget {
  const _LocationProductRow({
    required this.product,
    required this.quantity,
    required this.currency,
  });

  final Product product;
  final int quantity;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(product.category),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$quantity unidades'),
              const SizedBox(height: 4),
              Text(currency.format(product.price * quantity)),
            ],
          ),
        ],
      ),
    );
  }
}
