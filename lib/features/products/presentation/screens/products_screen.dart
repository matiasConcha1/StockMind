import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/app/routes.dart';
import 'package:stockmind/core/services/report_export_service.dart';
import 'package:stockmind/core/widgets/app_alert_dialog.dart';
import 'package:stockmind/core/widgets/empty_state.dart';
import 'package:stockmind/core/widgets/export_feedback.dart';
import 'package:stockmind/core/widgets/stockmind_loading_screen.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
import 'package:stockmind/features/company/providers/company_profile_provider.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/dashboard_frame.dart';
import 'package:stockmind/features/products/data/services/inventory_export_service.dart';
import 'package:stockmind/features/products/models/product.dart';
import 'package:stockmind/features/products/presentation/widgets/product_dialog.dart';
import 'package:stockmind/features/products/presentation/widgets/product_table.dart';
import 'package:stockmind/features/products/providers/products_provider.dart';
import 'package:stockmind/features/replenishment/presentation/widgets/stock_request_dialog.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductsProvider>();
    final auth = context.watch<AuthProvider>();
    final exportItems = provider.filteredProducts;

    return DashboardFrame(
      title: 'Productos',
      subtitle:
          'Gestiona tu catalogo por usuario, con filtros, exportacion y control inteligente del stock.',
      actions: [
        FilledButton.tonalIcon(
          onPressed: exportItems.isEmpty || !auth.canExport
              ? null
              : () => _exportCsv(context),
          icon: const Icon(Icons.download_rounded),
          label: const Text('Exportar CSV'),
        ),
        OutlinedButton.icon(
          onPressed: exportItems.isEmpty || !auth.canExport
              ? null
              : () => _exportLocationStockCsv(context),
          icon: const Icon(Icons.location_on_outlined),
          label: const Text('Stock x ubicación'),
        ),
        OutlinedButton.icon(
          onPressed: exportItems.isEmpty || !auth.canExport
              ? null
              : () => _exportExcel(context),
          icon: const Icon(Icons.table_chart_outlined),
          label: const Text('Exportar Excel'),
        ),
        FilledButton.tonalIcon(
          onPressed: exportItems.isEmpty || !auth.canExport
              ? null
              : () => _exportPdf(context),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Exportar PDF'),
        ),
        FilledButton.icon(
          onPressed: provider.isLoading || !auth.canEdit
              ? null
              : () => _openDialog(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nuevo producto'),
        ),
        FilledButton.tonalIcon(
          onPressed: auth.canEdit ? () => context.go(AppRoutePaths.scan) : null,
          icon: const Icon(Icons.qr_code_scanner_rounded),
          label: const Text('Escanear'),
        ),
        FilledButton.tonalIcon(
          onPressed: auth.canEdit
              ? () => context.go(AppRoutePaths.replenishment)
              : null,
          icon: const Icon(Icons.add_alert_outlined),
          label: const Text('Reposición'),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compactFilters = constraints.maxWidth < 1080;
          final useStackedFilters = constraints.maxWidth < 860;

          return Column(
            children: [
              if (provider.error != null) ...[
                _ProductsErrorBanner(message: provider.error!),
                const SizedBox(height: 16),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: useStackedFilters
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                            _FilterSelector(provider: provider),
                          ],
                        )
                      : compactFilters
                          ? Column(
                              children: [
                                TextField(
                                  onChanged: provider.updateSearchQuery,
                                  decoration: const InputDecoration(
                                    hintText:
                                        'Buscar por nombre, categoria o estado',
                                    prefixIcon: Icon(Icons.search_rounded),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String?>(
                                        initialValue: provider.categoryFilter,
                                        decoration: const InputDecoration(
                                          labelText: 'Categoria',
                                          prefixIcon:
                                              Icon(Icons.category_outlined),
                                        ),
                                        items: [
                                          const DropdownMenuItem<String?>(
                                            value: null,
                                            child: Text('Todas'),
                                          ),
                                          ...provider.categories.map(
                                            (category) =>
                                                DropdownMenuItem<String?>(
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
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: _FilterSelector(provider: provider),
                                      ),
                                    ),
                                  ],
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
                            Expanded(
                              flex: 3,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: _FilterSelector(provider: provider),
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
                      canEdit: auth.canEdit,
                      canDelete: auth.canDelete,
                      onEdit: (product) => _openDialog(context, product: product),
                      onDelete: (product) => _confirmDelete(context, product),
                      onRequestReplenishment: auth.canEdit
                          ? (product) => showStockRequestDialog(
                                context,
                                initialProduct: product,
                              )
                          : null,
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

  Future<void> _openDialog(
    BuildContext context, {
    Product? product,
    String? initialBarcode,
  }) async {
    final result = await showDialog<ProductDialogResult>(
      context: context,
      builder: (_) => ProductDialog(
        product: product,
        initialBarcode: initialBarcode,
      ),
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
      title: '¿Eliminar producto?',
      message:
          'El producto se archivará y dejará de aparecer en el inventario. Esta acción quedará registrada en el historial.',
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
          ? 'Producto archivado'
          : 'No se pudo eliminar el producto',
      message: provider.error == null
          ? 'El producto fue archivado correctamente y ya no aparece en el inventario.'
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

  Future<void> _exportCsv(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final company = context.read<CompanyProfileProvider>().profile;
    await runExportTask(
      context: context,
      hasData: context.read<ProductsProvider>().filteredProducts.isNotEmpty,
      noDataTitle: 'No hay datos para exportar',
      noDataMessage: 'Ajusta los filtros o crea productos antes de exportar.',
      successMessage: 'Los productos fueron descargados correctamente en CSV.',
      task: () => ReportExportService().exportProductsCsv(
        products: context.read<ProductsProvider>().filteredProducts,
        userName: auth.user?.displayName ?? auth.user?.email,
        companyProfile: company,
      ),
    );
  }

  Future<void> _exportLocationStockCsv(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final company = context.read<CompanyProfileProvider>().profile;
    await runExportTask(
      context: context,
      hasData: context.read<ProductsProvider>().filteredProducts.isNotEmpty,
      noDataTitle: 'No hay datos para exportar',
      noDataMessage:
          'Necesitas productos visibles en el filtro actual para exportar.',
      successMessage:
          'El stock distribuido por ubicaciÃ³n fue descargado correctamente.',
      task: () => ReportExportService().exportLocationStockCsv(
        products: context.read<ProductsProvider>().filteredProducts,
        userName: auth.user?.displayName ?? auth.user?.email,
        companyProfile: company,
      ),
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

class _FilterSelector extends StatelessWidget {
  const _FilterSelector({
    required this.provider,
  });

  final ProductsProvider provider;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _FilterChipButton(
          label: 'Todos',
          selected: provider.productFilter == ProductFilter.all,
          onTap: () => provider.updateProductFilter(ProductFilter.all),
        ),
        _FilterChipButton(
          label: 'En riesgo',
          selected: provider.productFilter == ProductFilter.atRisk,
          onTap: () => provider.updateProductFilter(ProductFilter.atRisk),
        ),
        _FilterChipButton(
          label: 'Óptimo',
          selected: provider.productFilter == ProductFilter.optimal,
          onTap: () => provider.updateProductFilter(ProductFilter.optimal),
        ),
      ],
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.16)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? colorScheme.primary.withValues(alpha: 0.45)
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.82),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
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
