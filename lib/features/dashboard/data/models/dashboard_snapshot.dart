import 'package:stockmind/features/dashboard/data/models/stock_movement.dart';
import 'package:stockmind/features/products/models/product.dart';
import 'package:stockmind/features/replenishment/models/stock_request.dart';

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.totalProducts,
    required this.totalLocations,
    required this.totalUnits,
    required this.outOfStockProducts,
    required this.lowStockProducts,
    required this.mediumStockProducts,
    required this.highStockProducts,
    required this.criticalProducts,
    required this.activeAlerts,
    required this.expiringSoonProducts,
    required this.expiredProducts,
    required this.categories,
    required this.totalInventoryValue,
    required this.topCategories,
    required this.lowestStockProducts,
    required this.recentlyUpdatedProducts,
    required this.recentMovements,
    required this.entriesToday,
    required this.exitsToday,
    required this.topMovedProductNames,
    required this.lowStockLocations,
    required this.outOfStockByLocation,
    required this.movementLocationNames,
    required this.pendingRequests,
    required this.completedRequestsThisWeek,
    required this.productsWithMoreRequests,
    required this.criticalWithoutRequest,
    required this.requests,
  });

  final int totalProducts;
  final int totalLocations;
  final int totalUnits;
  final int outOfStockProducts;
  final int lowStockProducts;
  final int mediumStockProducts;
  final int highStockProducts;
  final int criticalProducts;
  final int activeAlerts;
  final int expiringSoonProducts;
  final int expiredProducts;
  final int categories;
  final double totalInventoryValue;
  final List<CategorySlice> topCategories;
  final List<Product> lowestStockProducts;
  final List<Product> recentlyUpdatedProducts;
  final List<StockMovement> recentMovements;
  final int entriesToday;
  final int exitsToday;
  final List<String> topMovedProductNames;
  final List<LocationStockSlice> lowStockLocations;
  final List<String> outOfStockByLocation;
  final List<String> movementLocationNames;
  final int pendingRequests;
  final int completedRequestsThisWeek;
  final List<String> productsWithMoreRequests;
  final int criticalWithoutRequest;
  final List<StockRequest> requests;

  double get stockHealthScore {
    if (totalProducts == 0) return 100;
    final ratio = (outOfStockProducts + lowStockProducts + mediumStockProducts) /
        totalProducts;
    return ((1 - ratio) * 100).clamp(0, 100);
  }
}

class CategorySlice {
  const CategorySlice({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;
}

class LocationStockSlice {
  const LocationStockSlice({
    required this.label,
    required this.quantity,
  });

  final String label;
  final int quantity;
}
