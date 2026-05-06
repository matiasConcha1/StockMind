import 'package:stockmind/features/dashboard/data/models/dashboard_snapshot.dart';
import 'package:stockmind/features/dashboard/data/models/stock_movement.dart';
import 'package:stockmind/features/products/models/product.dart';
import 'package:stockmind/features/replenishment/models/stock_request.dart';

class StockService {
  DashboardSnapshot buildSnapshot(
    List<Product> products,
    int totalLocations,
    List<StockMovement> recentMovements,
    int activeAlerts,
    List<StockRequest> requests,
  ) {
    final byCategory = <String, double>{};
    final byLocation = <String, int>{};
    final outOfStockByLocation = <String>{};
    for (final product in products) {
      byCategory.update(
        product.category,
        (value) => value + product.inventoryValue,
        ifAbsent: () => product.inventoryValue,
      );
      for (final location in product.locationsStock) {
        byLocation.update(
          location.locationName,
          (value) => value + location.quantity,
          ifAbsent: () => location.quantity,
        );
        if (location.quantity <= 0) {
          outOfStockByLocation.add('${product.name} · ${location.locationName}');
        }
      }
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
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    var entriesToday = 0;
    var exitsToday = 0;
    final movementByProduct = <String, int>{};

    for (final movement in recentMovements) {
      final movementDay = DateTime(
        movement.createdAt.year,
        movement.createdAt.month,
        movement.createdAt.day,
      );
      if (movementDay == todayStart) {
        if (movement.isEntry) {
          entriesToday += movement.quantity;
        } else if (movement.isExit) {
          exitsToday += movement.quantity;
        }
      }

      movementByProduct.update(
        movement.productName,
        (value) => value + movement.quantity,
        ifAbsent: () => movement.quantity,
      );
    }

    final topMovedProductNames = movementByProduct.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final lowStockLocations = byLocation.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final movementByLocation = <String, int>{};
    for (final movement in recentMovements) {
      final locationLabel = movement.isTransfer
          ? '${movement.sourceLocationName ?? movement.locationName} → ${movement.targetLocationName ?? movement.locationName}'
          : movement.locationName;
      if (locationLabel.trim().isEmpty) continue;
      movementByLocation.update(
        locationLabel,
        (value) => value + movement.quantity,
        ifAbsent: () => movement.quantity,
      );
    }
    final movementLocationNames = movementByLocation.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final pendingRequests = requests.where((item) => item.isPending).length;
    final weekStart = todayStart.subtract(Duration(days: todayStart.weekday - 1));
    final completedRequestsThisWeek = requests.where((item) {
      if (!item.isCompleted || item.completedAt == null) return false;
      return !item.completedAt!.isBefore(weekStart);
    }).length;
    final requestByProduct = <String, int>{};
    for (final request in requests) {
      requestByProduct.update(
        request.productName,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    final productsWithMoreRequests = requestByProduct.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final pendingProductIds = requests
        .where((item) => item.isPending || item.isApproved)
        .map((item) => item.productId)
        .toSet();
    final criticalWithoutRequest = products
        .where((product) => product.isLowStock && !pendingProductIds.contains(product.id))
        .length;

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
          products.where((product) => product.isOptimal).length,
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
      entriesToday: entriesToday,
      exitsToday: exitsToday,
      topMovedProductNames: topMovedProductNames
          .take(3)
          .map((entry) => entry.key)
          .toList(),
      lowStockLocations: lowStockLocations
          .take(4)
          .map(
            (entry) => LocationStockSlice(
              label: entry.key,
              quantity: entry.value,
            ),
          )
          .toList(),
      outOfStockByLocation: outOfStockByLocation.take(4).toList(),
      movementLocationNames: movementLocationNames
          .take(4)
          .map((entry) => entry.key)
          .toList(),
      pendingRequests: pendingRequests,
      completedRequestsThisWeek: completedRequestsThisWeek,
      productsWithMoreRequests: productsWithMoreRequests
          .take(3)
          .map((entry) => entry.key)
          .toList(),
      criticalWithoutRequest: criticalWithoutRequest,
      requests: requests,
    );
  }
}
