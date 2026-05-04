import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stockmind/core/widgets/empty_state.dart';
import 'package:stockmind/features/products/models/product.dart';

class ProductTable extends StatelessWidget {
  const ProductTable({
    required this.products,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final List<Product> products;
  final ValueChanged<Product> onEdit;
  final ValueChanged<Product> onDelete;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 880;
    final currency = NumberFormat.currency(symbol: '\$');

    if (products.isEmpty) {
      return const Card(
        child: SizedBox(
          height: 320,
          child: EmptyState(
            title: 'Sin productos todavía',
            subtitle:
                'Crea tu primer producto para comenzar a operar con inventario real.',
            icon: Icons.inventory_2_outlined,
          ),
        ),
      );
    }

    if (isCompact) {
      return Column(
        children: products
            .map(
              (product) => Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          _StockBadge(product: product),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(product.category),
                      const SizedBox(height: 6),
                      Text('Precio: ${currency.format(product.price)}'),
                      Text('Stock total: ${product.totalStock}'),
                      Text('Stock mínimo: ${product.minStock}'),
                      Text(
                        product.hasLocationAssignments
                            ? '${product.locationQuantities.length} ubicaciones asignadas'
                            : 'Sin ubicaciones asignadas',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () => onEdit(product),
                            child: const Text('Editar'),
                          ),
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed: () => onDelete(product),
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Producto')),
            DataColumn(label: Text('Categoría')),
            DataColumn(label: Text('Precio')),
            DataColumn(label: Text('Stock total')),
            DataColumn(label: Text('Ubicaciones')),
            DataColumn(label: Text('Stock mínimo')),
            DataColumn(label: Text('Estado')),
            DataColumn(label: Text('Acciones')),
          ],
          rows: products.map((product) {
            return DataRow(
              cells: [
                DataCell(Text(product.name)),
                DataCell(Text(product.category)),
                DataCell(Text(currency.format(product.price))),
                DataCell(Text(product.totalStock.toString())),
                DataCell(
                  Text(
                    product.hasLocationAssignments
                        ? product.locationQuantities.length.toString()
                        : '0',
                  ),
                ),
                DataCell(Text(product.minStock.toString())),
                DataCell(_StockBadge(product: product)),
                DataCell(
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () => onEdit(product),
                        child: const Text('Editar'),
                      ),
                      TextButton(
                        onPressed: () => onDelete(product),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final low = product.isLowStock;
    final critical = product.isCriticalStock;
    final backgroundColor = critical
        ? const Color(0xFFEF4444)
        : low
            ? Colors.orange
            : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        critical
            ? 'Crítico'
            : low
                ? 'Bajo stock'
                : 'Estable',
        style: TextStyle(
          color: critical
              ? const Color(0xFFB91C1C)
              : low
                  ? Colors.orange.shade800
                  : Colors.green.shade800,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
