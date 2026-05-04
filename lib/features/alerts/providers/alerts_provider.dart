import 'package:flutter/foundation.dart';
import 'package:stockmind/features/products/models/product.dart';
import 'package:stockmind/features/products/providers/products_provider.dart';

class AlertsProvider extends ChangeNotifier {
  AlertsProvider({
    required ProductsProvider productsProvider,
  }) : _productsProvider = productsProvider {
    _productsProvider.addListener(notifyListeners);
  }

  final ProductsProvider _productsProvider;

  List<Product> get lowStockProducts => _productsProvider.lowStockProducts;
  int get totalProducts => _productsProvider.products.length;

  int get activeAlerts => lowStockProducts.length;

  int get coveragePercentage {
    if (totalProducts == 0) return 0;
    return (((totalProducts - activeAlerts) / totalProducts) * 100).round();
  }

  @override
  void dispose() {
    _productsProvider.removeListener(notifyListeners);
    super.dispose();
  }
}
