import 'package:flutter/material.dart';
import 'package:stockmind/models/dashboard_metric.dart';
import 'package:stockmind/models/inventory_movement.dart';
import 'package:stockmind/models/product.dart';
import 'package:stockmind/services/inventory_service.dart';

class InventoryController extends ChangeNotifier {
  InventoryController(this._inventoryService) {
    _loadInitialData();
  }

  final InventoryService _inventoryService;

  List<Product> _products = const [];
  List<InventoryMovement> _movements = const [];
  String _searchQuery = '';

  List<Product> get products => List.unmodifiable(_products);
  List<InventoryMovement> get recentMovements => List.unmodifiable(
        _movements.take(6),
      );

  List<Product> get filteredProducts {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return products;
    return _products
        .where((product) => product.name.toLowerCase().contains(query))
        .toList();
  }

  List<Product> get lowStockProducts =>
      _products.where((product) => product.isLowStock).toList();

  List<DashboardMetric> get metrics => [
        DashboardMetric(
          title: 'Total productos',
          value: _products.length.toString(),
          subtitle: 'Inventario activo',
          icon: Icons.inventory_2_rounded,
          color: const Color(0xFF1D4ED8),
        ),
        DashboardMetric(
          title: 'Bajo stock',
          value: lowStockProducts.length.toString(),
          subtitle: 'Requieren reposición',
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFF59E0B),
        ),
        DashboardMetric(
          title: 'Movimientos',
          value: _movements.length.toString(),
          subtitle: 'Últimas operaciones',
          icon: Icons.swap_horiz_rounded,
          color: const Color(0xFF0F766E),
        ),
      ];

  List<StockChartPoint> get stockChartData {
    final topProducts = [..._products]
      ..sort((a, b) => b.quantity.compareTo(a.quantity));
    return topProducts.take(6).toList().asMap().entries.map((entry) {
      final product = entry.value;
      return StockChartPoint(
        index: entry.key,
        label: product.name,
        quantity: product.quantity,
      );
    }).toList();
  }

  void updateSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  Future<void> createProduct({
    required String name,
    required int quantity,
    required int minimumStock,
  }) async {
    final product = Product(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      quantity: quantity,
      minimumStock: minimumStock,
      updatedAt: DateTime.now(),
    );
    await _inventoryService.createProduct(product);
    _refresh();
  }

  Future<void> updateProduct({
    required Product original,
    required String name,
    required int quantity,
    required int minimumStock,
  }) async {
    await _inventoryService.updateProduct(
      original.copyWith(
        name: name,
        quantity: quantity,
        minimumStock: minimumStock,
        updatedAt: DateTime.now(),
      ),
    );
    _refresh();
  }

  Future<void> deleteProduct(String productId) async {
    await _inventoryService.deleteProduct(productId);
    _refresh();
  }

  void _loadInitialData() {
    _products = _inventoryService.getProducts();
    _movements = _inventoryService.getMovements();
  }

  void _refresh() {
    _products = _inventoryService.getProducts();
    _movements = _inventoryService.getMovements();
    notifyListeners();
  }
}

class StockChartPoint {
  const StockChartPoint({
    required this.index,
    required this.label,
    required this.quantity,
  });

  final int index;
  final String label;
  final int quantity;
}
