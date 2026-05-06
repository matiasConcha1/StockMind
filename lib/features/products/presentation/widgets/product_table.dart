import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stockmind/core/widgets/empty_state.dart';
import 'package:stockmind/core/widgets/remote_image_frame.dart';
import 'package:stockmind/features/products/models/product.dart';
import 'package:stockmind/features/products/presentation/widgets/stock_status_badge.dart';

class ProductTable extends StatelessWidget {
  const ProductTable({
    required this.products,
    required this.onEdit,
    required this.onDelete,
    required this.canEdit,
    required this.canDelete,
    super.key,
  });

  final List<Product> products;
  final ValueChanged<Product> onEdit;
  final ValueChanged<Product> onDelete;
  final bool canEdit;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$');

    if (products.isEmpty) {
      return const Card(
        child: SizedBox(
          height: 320,
          child: EmptyState(
            title: 'Sin productos todavia',
            subtitle:
                'Crea tu primer producto para comenzar a operar con inventario real.',
            icon: Icons.inventory_2_outlined,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 1180;

        if (isCompact) {
          return Column(
            children: products
                .map(
                  (product) => _CompactProductCard(
                    product: product,
                    currency: currency,
                    canEdit: canEdit,
                    canDelete: canDelete,
                    onEdit: () => onEdit(product),
                    onDelete: () => onDelete(product),
                  ),
                )
                .toList(),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                const _DesktopTableHeader(),
                const SizedBox(height: 8),
                for (final product in products)
                  _DesktopProductRow(
                    product: product,
                    currency: currency,
                    canEdit: canEdit,
                    canDelete: canDelete,
                    onEdit: () => onEdit(product),
                    onDelete: () => onDelete(product),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DesktopTableHeader extends StatelessWidget {
  const _DesktopTableHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.32,
            ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          _HeaderCell(label: 'Producto', flex: 4),
          _HeaderCell(label: 'Precio', flex: 2),
          _HeaderCell(label: 'Stock', flex: 2),
          _HeaderCell(label: 'Ubicaciones', flex: 2),
          _HeaderCell(label: 'Estado', flex: 2),
          _HeaderCell(label: 'Acciones', flex: 3),
        ],
      ),
    )._withTextStyle(style);
  }
}

extension on Widget {
  Widget _withTextStyle(TextStyle? style) {
    if (style == null) return this;
    return DefaultTextStyle.merge(style: style, child: this);
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.label,
    required this.flex,
  });

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _DesktopProductRow extends StatefulWidget {
  const _DesktopProductRow({
    required this.product,
    required this.currency,
    required this.canEdit,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final NumberFormat currency;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_DesktopProductRow> createState() => _DesktopProductRowState();
}

class _DesktopProductRowState extends State<_DesktopProductRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final product = widget.product;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: _hovered
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.22)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered
                ? colorScheme.primary.withValues(alpha: 0.22)
                : colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: _ProductIdentity(product: product),
            ),
            Expanded(
              flex: 2,
              child: Text(
                widget.currency.format(product.price),
                style: theme.textTheme.titleSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${product.totalStock} unid.',
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Minimo ${product.minStock}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.68),
                    ),
                  ),
                  if (product.expiryDate != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      product.isExpired
                          ? 'Vencido'
                          : 'Vence ${DateFormat('dd/MM').format(product.expiryDate!)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: product.isExpired
                            ? colorScheme.error
                            : colorScheme.onSurface.withValues(alpha: 0.68),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                product.hasLocationAssignments
                    ? '${product.locationQuantities.length} zonas'
                    : 'Sin asignar',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: StockStatusBadge(product: product),
              ),
            ),
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.canEdit)
                      OutlinedButton.icon(
                        onPressed: widget.onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Editar'),
                      ),
                    if (widget.canEdit && widget.canDelete)
                      const SizedBox(height: 8),
                    if (widget.canDelete)
                      TextButton.icon(
                        onPressed: widget.onDelete,
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: colorScheme.error,
                        ),
                        label: Text(
                          'Eliminar',
                          style: TextStyle(color: colorScheme.error),
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

class _CompactProductCard extends StatelessWidget {
  const _CompactProductCard({
    required this.product,
    required this.currency,
    required this.canEdit,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final NumberFormat currency;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _ProductIdentity(product: product)),
                const SizedBox(width: 8),
                if (canEdit || canDelete)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      if (canEdit)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Editar'),
                        ),
                      if (canDelete)
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Eliminar',
                            style: TextStyle(color: colorScheme.error),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _InfoPill(label: currency.format(product.price)),
                _InfoPill(label: '${product.totalStock} unidades'),
                _InfoPill(
                  label: '${product.locationQuantities.length} ubicaciones',
                ),
                if (product.expiryDate != null)
                  _InfoPill(
                    label: product.isExpired
                        ? 'Vencido'
                        : 'Vence ${DateFormat('dd/MM').format(product.expiryDate!)}',
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: StockStatusBadge(product: product, compact: true),
                ),
                const SizedBox(width: 10),
                Text(
                  'Minimo ${product.minStock}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.68),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductIdentity extends StatelessWidget {
  const _ProductIdentity({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        RemoteImageFrame(
          size: 52,
          imageUrl: product.imageUrl,
          icon: Icons.inventory_2_outlined,
          borderRadius: BorderRadius.circular(16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                product.category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.68),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.42,
            ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label),
    );
  }
}
