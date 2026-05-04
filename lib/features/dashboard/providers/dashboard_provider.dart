import 'package:flutter/foundation.dart';
import 'package:stockmind/features/dashboard/data/models/dashboard_snapshot.dart';
import 'package:stockmind/features/dashboard/data/services/stock_service.dart';
import 'package:stockmind/features/products/models/product.dart';
import 'package:stockmind/features/products/providers/products_provider.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({
    required ProductsProvider productsProvider,
    required StockService stockService,
  })  : _productsProvider = productsProvider,
        _stockService = stockService {
    _productsProvider.addListener(_syncFromProducts);
    _syncFromProducts();
  }

  final ProductsProvider _productsProvider;
  final StockService _stockService;

  DashboardSnapshot _snapshot = const DashboardSnapshot(
    totalProducts: 0,
    totalUnits: 0,
    lowStockProducts: 0,
    categories: 0,
    totalInventoryValue: 0,
    topCategories: [],
    topProducts: [],
  );

  DashboardSnapshot get snapshot => _snapshot;
  List<Product> get lowStockProducts => _productsProvider.lowStockProducts;
  bool get isLoading => _productsProvider.isLoading;
  String? get error => _productsProvider.error;
  bool get hasProducts => _productsProvider.hasProducts;

  void _syncFromProducts() {
    _snapshot = _stockService.buildSnapshot(_productsProvider.products);
    notifyListeners();
  }

  @override
  void dispose() {
    _productsProvider.removeListener(_syncFromProducts);
    super.dispose();
  }
}
