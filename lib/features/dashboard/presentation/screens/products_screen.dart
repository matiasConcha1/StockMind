import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/dashboard_frame.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/product_dialog.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/product_table.dart';
import 'package:stockmind/models/product.dart';
import 'package:stockmind/providers/products_provider.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductsProvider>();
    final isCompact = MediaQuery.sizeOf(context).width < 860;

    return DashboardFrame(
      title: 'Productos',
      subtitle: 'Alta, edición, filtros y control fino del catálogo.',
      actions: [
        FilledButton.icon(
          onPressed: () => _openDialog(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nuevo producto'),
        ),
      ],
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: isCompact
                  ? Column(
                      children: [
                        TextField(
                          onChanged: provider.updateSearchQuery,
                          decoration: const InputDecoration(
                            hintText: 'Buscar por nombre, categoría o SKU',
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
                              hintText: 'Buscar por nombre, categoría o SKU',
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
          ProductTable(
            products: provider.filteredProducts,
            onEdit: (product) => _openDialog(context, product: product),
            onDelete: (product) => _confirmDelete(context, product),
          ),
        ],
      ),
    );
  }

  Future<void> _openDialog(BuildContext context, {Product? product}) async {
    final result = await showDialog<Product>(
      context: context,
      builder: (_) => ProductDialog(product: product),
    );

    if (result == null || !context.mounted) return;
    final provider = context.read<ProductsProvider>();
    if (product == null) {
      await provider.createProduct(result);
    } else {
      await provider.updateProduct(result);
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
