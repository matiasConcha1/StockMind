import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/core/widgets/empty_state.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/dashboard_frame.dart';
import 'package:stockmind/features/products/models/product.dart';
import 'package:stockmind/features/products/presentation/widgets/product_dialog.dart';
import 'package:stockmind/features/products/presentation/widgets/product_table.dart';
import 'package:stockmind/features/products/providers/products_provider.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductsProvider>();
    final isCompact = MediaQuery.sizeOf(context).width < 860;

    return DashboardFrame(
      title: 'Productos',
      subtitle: 'Gestiona tu catálogo real por usuario, con filtros y control de stock.',
      actions: [
        FilledButton.icon(
          onPressed: provider.isLoading ? null : () => _openDialog(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nuevo producto'),
        ),
      ],
      child: Column(
        children: [
          if (provider.error != null) ...[
            _ProductsErrorBanner(message: provider.error!),
            const SizedBox(height: 16),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: isCompact
                  ? Column(
                      children: [
                        TextField(
                          onChanged: provider.updateSearchQuery,
                          decoration: const InputDecoration(
                            hintText: 'Buscar por nombre, categoría o estado',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String?>(
                          initialValue: provider.categoryFilter,
                          decoration: const InputDecoration(labelText: 'Categoría'),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Todas'),
                            ),
                            ...provider.categories.map(
                              (category) => DropdownMenuItem<String?>(
                                value: category,
                                child: Text(category),
                              ),
                            ),
                          ],
                          onChanged: provider.updateCategoryFilter,
                        ),
                        const SizedBox(height: 14),
                        SegmentedButton<ProductFilter>(
                          segments: const [
                            ButtonSegment(
                              value: ProductFilter.all,
                              label: Text('Todos'),
                            ),
                            ButtonSegment(
                              value: ProductFilter.lowStock,
                              label: Text('Bajo stock'),
                            ),
                          ],
                          selected: {provider.productFilter},
                          onSelectionChanged: (value) {
                            provider.updateProductFilter(value.first);
                          },
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: TextField(
                            onChanged: provider.updateSearchQuery,
                            decoration: const InputDecoration(
                              hintText: 'Buscar por nombre, categoría o estado',
                              prefixIcon: Icon(Icons.search_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String?>(
                            initialValue: provider.categoryFilter,
                            decoration: const InputDecoration(labelText: 'Categoría'),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Todas'),
                              ),
                              ...provider.categories.map(
                                (category) => DropdownMenuItem<String?>(
                                  value: category,
                                  child: Text(category),
                                ),
                              ),
                            ],
                            onChanged: provider.updateCategoryFilter,
                          ),
                        ),
                        const SizedBox(width: 14),
                        SegmentedButton<ProductFilter>(
                          segments: const [
                            ButtonSegment(
                              value: ProductFilter.all,
                              label: Text('Todos'),
                            ),
                            ButtonSegment(
                              value: ProductFilter.lowStock,
                              label: Text('Bajo stock'),
                            ),
                          ],
                          selected: {provider.productFilter},
                          onSelectionChanged: (value) {
                            provider.updateProductFilter(value.first);
                          },
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          if (provider.isLoading && !provider.hasProducts)
            const Card(
              child: SizedBox(
                height: 320,
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (!provider.isLoading &&
              provider.hasProducts &&
              provider.filteredProducts.isEmpty)
            const Card(
              child: SizedBox(
                height: 320,
                child: EmptyState(
                  title: 'Sin coincidencias',
                  subtitle:
                      'No encontramos productos con los filtros actuales. Ajusta la búsqueda o la categoría.',
                  icon: Icons.filter_alt_off_outlined,
                ),
              ),
            )
          else
            Stack(
              children: [
                ProductTable(
                  products: provider.filteredProducts,
                  onEdit: (product) => _openDialog(context, product: product),
                  onDelete: (product) => _confirmDelete(context, product),
                ),
                if (provider.isLoading && provider.hasProducts)
                  const Positioned(
                    top: 12,
                    right: 12,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _openDialog(BuildContext context, {Product? product}) async {
    final result = await showDialog<ProductDialogResult>(
      context: context,
      builder: (_) => ProductDialog(product: product),
    );

    if (result == null || !context.mounted) return;
    final provider = context.read<ProductsProvider>();
    if (product == null) {
      await provider.createProduct(result.product);
    } else {
      await provider.updateProduct(
        result.product,
        stockChangeReason: result.stockChangeReason,
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, Product product) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Deseas eliminar "${product.name}" del catálogo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && context.mounted) {
      await context.read<ProductsProvider>().deleteProduct(product.id);
    }
  }
}

class _ProductsErrorBanner extends StatelessWidget {
  const _ProductsErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
