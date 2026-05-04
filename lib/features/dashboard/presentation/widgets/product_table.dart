import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stockmind/models/product.dart';

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
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No hay productos que coincidan con los filtros actuales.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
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
                      Text('${product.category} · ${product.sku}'),
                      const SizedBox(height: 6),
                      Text('Precio: ${currency.format(product.price)}'),
                      Text('Stock: ${product.stock}'),
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
            DataColumn(label: Text('SKU')),
            DataColumn(label: Text('Precio')),
            DataColumn(label: Text('Stock')),
            DataColumn(label: Text('Estado')),
            DataColumn(label: Text('Acciones')),
          ],
          rows: products.map((product) {
            return DataRow(
              cells: [
                DataCell(Text(product.name)),
                DataCell(Text(product.category)),
                DataCell(Text(product.sku)),
                DataCell(Text(currency.format(product.price))),
                DataCell(Text(product.stock.toString())),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (low ? Colors.orange : Colors.green).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        low ? 'Bajo stock' : 'Estable',
        style: TextStyle(
          color: low ? Colors.orange.shade800 : Colors.green.shade800,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
