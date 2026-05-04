import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stockmind/models/product.dart';
import 'package:stockmind/widgets/common/section_card.dart';

class ProductTableCard extends StatelessWidget {
  const ProductTableCard({
    super.key,
    required this.products,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Product> products;
  final ValueChanged<Product> onEdit;
  final ValueChanged<Product> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Listado de productos', style: theme.textTheme.titleLarge),
          const SizedBox(height: 18),
          if (products.isEmpty)
            Text(
              'No hay productos que coincidan con la búsqueda actual.',
              style: theme.textTheme.bodyMedium,
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Producto')),
                  DataColumn(label: Text('Cantidad')),
                  DataColumn(label: Text('Mínimo')),
                  DataColumn(label: Text('Estado')),
                  DataColumn(label: Text('Actualizado')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: products.map((product) {
                  return DataRow(
                    cells: [
                      DataCell(Text(product.name)),
                      DataCell(Text(product.quantity.toString())),
                      DataCell(Text(product.minimumStock.toString())),
                      DataCell(
                        _StatusChip(
                          label: product.isLowStock ? 'Bajo stock' : 'Estable',
                          color: product.isLowStock
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF0F766E),
                        ),
                      ),
                      DataCell(Text(dateFormat.format(product.updatedAt))),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => onEdit(product),
                              icon: const Icon(Icons.edit_rounded),
                              tooltip: 'Editar',
                            ),
                            IconButton(
                              onPressed: () => onDelete(product),
                              icon: const Icon(Icons.delete_outline_rounded),
                              tooltip: 'Eliminar',
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}
