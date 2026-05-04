import 'package:stockmind/features/dashboard/data/models/dashboard_snapshot.dart';
import 'package:stockmind/features/products/models/product.dart';

class StockService {
  DashboardSnapshot buildSnapshot(List<Product> products) {
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
    final topProducts = [...products]..sort((a, b) => b.stock.compareTo(a.stock));

    return DashboardSnapshot(
      totalProducts: products.length,
      totalUnits: products.fold(0, (sum, item) => sum + item.stock),
      lowStockProducts: products.where((product) => product.isLowStock).length,
      categories: products.map((item) => item.category).toSet().length,
      totalInventoryValue:
          products.fold(0, (sum, item) => sum + item.inventoryValue),
      topCategories: topCategories
          .take(5)
          .map((entry) => CategorySlice(label: entry.key, value: entry.value))
          .toList(),
      topProducts: topProducts.take(6).toList(),
    );
  }
}
