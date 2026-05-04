import 'package:stockmind/models/product.dart';

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.totalProducts,
    required this.totalUnits,
    required this.lowStockProducts,
    required this.categories,
    required this.totalInventoryValue,
    required this.topCategories,
    required this.topProducts,
  });

  final int totalProducts;
  final int totalUnits;
  final int lowStockProducts;
  final int categories;
  final double totalInventoryValue;
  final List<CategorySlice> topCategories;
  final List<Product> topProducts;

  double get stockHealthScore {
    if (totalProducts == 0) return 100;
    final ratio = lowStockProducts / totalProducts;
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
