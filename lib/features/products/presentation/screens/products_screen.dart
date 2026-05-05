import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/core/widgets/app_alert_dialog.dart';
import 'package:stockmind/core/widgets/empty_state.dart';
import 'package:stockmind/core/widgets/stockmind_loading_screen.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/dashboard_frame.dart';
import 'package:stockmind/features/products/data/services/inventory_export_service.dart';
import 'package:stockmind/features/products/models/product.dart';
import 'package:stockmind/features/products/presentation/widgets/product_dialog.dart';
import 'package:stockmind/features/products/presentation/widgets/product_table.dart';
import 'package:stockmind/features/products/providers/products_provider.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductsProvider>();
    final exportItems = provider.filteredProducts;

    return DashboardFrame(
      title: 'Productos',
      subtitle:
          'Gestiona tu catalogo por usuario, con filtros, exportacion y control inteligente del stock.',
      actions: [
        OutlinedButton.icon(
          onPressed: exportItems.isEmpty ? null : () => _exportExcel(context),
          icon: const Icon(Icons.table_chart_outlined),
          label: const Text('Exportar Excel'),
        ),
        FilledButton.tonalIcon(
          onPressed: exportItems.isEmpty ? null : () => _exportPdf(context),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Exportar PDF'),
        ),
        FilledButton.icon(
          onPressed: provider.isLoading ? null : () => _openDialog(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nuevo producto'),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compactFilters = constraints.maxWidth < 1080;

          return Column(
            children: [
              if (provider.error != null) ...[
                _ProductsErrorBanner(message: provider.error!),
                const SizedBox(height: 16),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: compactFilters
                      ? Column(
                          children: [
                            TextField(
                              onChanged: provider.updateSearchQuery,
                              decoration: const InputDecoration(
                                hintText: 'Buscar por nombre, categoria o estado',
                                prefixIcon: Icon(Icons.search_rounded),
                              ),
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String?>(
                              initialValue: provider.categoryFilter,
                              decoration: const InputDecoration(
                                labelText: 'Categoria',
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Todas'),
                                ),
                                ...provider.categories.map(
                                  (category) => DropdownMenuItem<String?>(
                                    value: category,
                                    child: Text(
                                      category,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: provider.updateCategoryFilter,
                            ),
                            const SizedBox(height: 14),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SegmentedButton<ProductFilter>(
                                  segments: const [
                                    ButtonSegment(
                                      value: ProductFilter.all,
                                      label: Text('Todos'),
                                    ),
                                    ButtonSegment(
                                      value: ProductFilter.atRisk,
                                      label: Text('En riesgo'),
                                    ),
                                    ButtonSegment(
                                      value: ProductFilter.healthy,
                                      label: Text('Saludable'),
                                    ),
                                  ],
                                  selected: {provider.productFilter},
                                  onSelectionChanged: (value) {
                                    provider.updateProductFilter(value.first);
                                  },
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 4,
                              child: TextField(
                                onChanged: provider.updateSearchQuery,
                                decoration: const InputDecoration(
                                  hintText: 'Buscar por nombre, categoria o estado',
                                  prefixIcon: Icon(Icons.search_rounded),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String?>(
                                initialValue: provider.categoryFilter,
                                decoration: const InputDecoration(
                                  labelText: 'Categoria',
                                  prefixIcon: Icon(Icons.category_outlined),
                                ),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('Todas'),
                                  ),
                                  ...provider.categories.map(
                                    (category) => DropdownMenuItem<String?>(
                                      value: category,
                                      child: Text(
                                        category,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: provider.updateCategoryFilter,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Flexible(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SegmentedButton<ProductFilter>(
                                    segments: const [
                                      ButtonSegment(
                                        value: ProductFilter.all,
                                        label: Text('Todos'),
                                      ),
                                      ButtonSegment(
                                        value: ProductFilter.atRisk,
                                        label: Text('En riesgo'),
                                      ),
                                      ButtonSegment(
                                        value: ProductFilter.healthy,
                                        label: Text('Saludable'),
                                      ),
                                    ],
                                    selected: {provider.productFilter},
                                    onSelectionChanged: (value) {
                                      provider.updateProductFilter(value.first);
                                    },
                                  ),
                                ),
                              ),
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
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: StockMindLoadingPanel(
                          compact: true,
                          statusMessage: 'Cargando productos...',
                        ),
                      ),
                    ),
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
                          'No encontramos productos con los filtros actuales. Ajusta la busqueda o la categoria.',
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
          );
        },
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
      await provider.createProduct(
        result.product,
        imageFile: result.imageFile,
      );
      if (!context.mounted) return;
      await showAppAlertDialog(
        context,
        type: provider.error == null ? AppAlertType.success : AppAlertType.error,
        title: provider.error == null
            ? 'Producto creado'
            : 'No se pudo crear el producto',
        message: provider.error == null
            ? 'El producto fue agregado correctamente al inventario.'
            : provider.error!,
      );
      return;
    }

    await provider.updateProduct(
      result.product,
      stockChangeReason: result.stockChangeReason,
      imageFile: result.imageFile,
      removeImage: result.removeImage,
    );
    if (!context.mounted) return;
    await showAppAlertDialog(
      context,
      type: provider.error == null ? AppAlertType.success : AppAlertType.error,
      title: provider.error == null
          ? 'Producto actualizado'
          : 'No se pudo actualizar el producto',
      message: provider.error == null
          ? 'Los cambios fueron guardados correctamente.'
          : provider.error!,
    );
  }

  Future<void> _confirmDelete(BuildContext context, Product product) async {
    final shouldDelete = await showAppConfirmDialog(
      context,
      title: 'Eliminar producto?',
      message:
          'Esta accion eliminara el producto del inventario y no se puede deshacer.',
      confirmLabel: 'Eliminar',
      cancelLabel: 'Cancelar',
    );

    if (!shouldDelete || !context.mounted) return;
    final provider = context.read<ProductsProvider>();
    await provider.deleteProduct(product.id);
    if (!context.mounted) return;
    await showAppAlertDialog(
      context,
      type: provider.error == null ? AppAlertType.success : AppAlertType.error,
      title: provider.error == null
          ? 'Producto eliminado'
          : 'No se pudo eliminar el producto',
      message: provider.error == null
          ? 'El producto fue eliminado correctamente.'
          : provider.error!,
    );
  }

  Future<void> _exportExcel(BuildContext context) async {
    await _runExport(
      context,
      () => InventoryExportService().exportProductsToExcel(
        context.read<ProductsProvider>().filteredProducts,
      ),
      successMessage: 'El inventario fue exportado correctamente en Excel.',
    );
  }

  Future<void> _exportPdf(BuildContext context) async {
    await _runExport(
      context,
      () => InventoryExportService().exportProductsToPdf(
        context.read<ProductsProvider>().filteredProducts,
      ),
      successMessage: 'El inventario fue exportado correctamente en PDF.',
    );
  }

  Future<void> _runExport(
    BuildContext context,
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    try {
      await action();
      if (!context.mounted) return;
      await showAppAlertDialog(
        context,
        type: AppAlertType.success,
        title: 'Exportacion completada',
        message: successMessage,
      );
    } catch (error) {
      if (!context.mounted) return;
      await showAppAlertDialog(
        context,
        type: AppAlertType.error,
        title: 'No se pudo exportar',
        message: error.toString().trim().isNotEmpty
            ? error.toString().trim()
            : 'No pudimos completar la exportacion. Intentalo nuevamente.',
      );
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
