import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/controllers/inventory_controller.dart';
import 'package:stockmind/models/product.dart';
import 'package:stockmind/widgets/dashboard/product_form_dialog.dart';
import 'package:stockmind/widgets/dashboard/product_table_card.dart';
import 'package:stockmind/widgets/layout/dashboard_header.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryController>();

    return SafeArea(
      child: Builder(
        builder: (context) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              DashboardHeader(
                title: 'Productos',
                subtitle:
                    'Administra altas, edición y eliminación del inventario.',
                onMenuPressed: () => Scaffold.of(context).openDrawer(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: inventory.updateSearchQuery,
                      decoration: const InputDecoration(
                        hintText: 'Buscar producto...',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: () => _openProductDialog(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Nuevo producto'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ProductTableCard(
                products: inventory.filteredProducts,
                onEdit: (product) =>
                    _openProductDialog(context, product: product),
                onDelete: (product) => _confirmDelete(context, product),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openProductDialog(BuildContext context,
      {Product? product}) async {
    final draft = await showDialog<ProductDraft>(
      context: context,
      builder: (_) => ProductFormDialog(product: product),
    );

    if (draft == null || !context.mounted) return;

    final inventory = context.read<InventoryController>();
    if (product == null) {
      await inventory.createProduct(
        name: draft.name,
        quantity: draft.quantity,
        minimumStock: draft.minimumStock,
      );
    } else {
      await inventory.updateProduct(
        original: product,
        name: draft.name,
        quantity: draft.quantity,
        minimumStock: draft.minimumStock,
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Deseas eliminar "${product.name}" del inventario?'),
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

    if (confirmed == true && context.mounted) {
      await context.read<InventoryController>().deleteProduct(product.id);
    }
  }
}
