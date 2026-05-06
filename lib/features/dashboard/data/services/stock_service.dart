import 'package:stockmind/features/dashboard/data/models/dashboard_snapshot.dart';
import 'package:stockmind/features/dashboard/data/models/stock_movement.dart';
import 'package:stockmind/features/products/models/product.dart';

class StockService {
  DashboardSnapshot buildSnapshot(
    List<Product> products,
    int totalLocations,
    List<StockMovement> recentMovements,
    int activeAlerts,
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
        final priorityA = a.stockStatus.priority;
        final priorityB = b.stockStatus.priority;
        if (priorityA != priorityB) {
          return priorityA.compareTo(priorityB);
        }
        return a.stock.compareTo(b.stock);
      });
    final recentlyUpdatedProducts = [...products]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return DashboardSnapshot(
      totalProducts: products.length,
      totalLocations: totalLocations,
      totalUnits: products.fold(0, (sum, item) => sum + item.stock),
      outOfStockProducts:
          products.where((product) => product.isCriticalStock).length,
      lowStockProducts: products
          .where((product) => product.stockStatus.isLowStock)
          .length,
      mediumStockProducts: products
          .where((product) => product.stockStatus.isMediumStock)
          .length,
      highStockProducts:
          products.where((product) => product.stockStatus.isHighStock).length,
      criticalProducts: products.where((product) => product.isCriticalStock).length,
      activeAlerts: activeAlerts,
      expiringSoonProducts: products
          .where((product) => !product.isExpired && product.expiresWithin7Days)
          .length,
      expiredProducts: products.where((product) => product.isExpired).length,
      categories: products.map((item) => item.category).toSet().length,
      totalInventoryValue:
          products.fold(0, (sum, item) => sum + item.inventoryValue),
      topCategories: topCategories
          .take(5)
          .map((entry) => CategorySlice(label: entry.key, value: entry.value))
          .toList(),
      lowestStockProducts: lowestStockProducts.take(6).toList(),
      recentlyUpdatedProducts: recentlyUpdatedProducts.take(5).toList(),
      recentMovements: recentMovements,
    );
  }
}
