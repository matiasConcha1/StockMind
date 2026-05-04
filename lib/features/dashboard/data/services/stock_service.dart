import 'package:stockmind/features/dashboard/data/models/dashboard_snapshot.dart';
import 'package:stockmind/features/dashboard/data/models/stock_movement.dart';
import 'package:stockmind/features/products/models/product.dart';

class StockService {
  DashboardSnapshot buildSnapshot(
    List<Product> products,
    List<StockMovement> recentMovements,
  ) {
    final byCategory = <String, double>{};
    for (final product in products) {
      byCategory.update(
        product.category,
        (value) => value + product.inventoryValue,
        ifAbsent: () => product.inventoryValue,
      );
    }

    final topCategories = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final lowestStockProducts = [...products]
      ..sort((a, b) {
        final lowPriorityA = a.isLowStock ? 0 : 1;
        final lowPriorityB = b.isLowStock ? 0 : 1;
        if (lowPriorityA != lowPriorityB) {
          return lowPriorityA.compareTo(lowPriorityB);
        }
        return a.stock.compareTo(b.stock);
      });

    return DashboardSnapshot(
      totalProducts: products.length,
      totalUnits: products.fold(0, (sum, item) => sum + item.stock),
      lowStockProducts: products.where((product) => product.isLowStock).length,
      criticalProducts: products.where((product) => product.isCriticalStock).length,
      categories: products.map((item) => item.category).toSet().length,
      totalInventoryValue:
          products.fold(0, (sum, item) => sum + item.inventoryValue),
      topCategories: topCategories
          .take(5)
          .map((entry) => CategorySlice(label: entry.key, value: entry.value))
          .toList(),
      lowestStockProducts: lowestStockProducts.take(6).toList(),
      recentMovements: recentMovements,
    );
  }
}
