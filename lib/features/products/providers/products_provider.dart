import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
import 'package:stockmind/features/products/data/services/product_service.dart';
import 'package:stockmind/features/products/models/product.dart';

enum ProductFilter { all, lowStock }

class ProductsProvider extends ChangeNotifier {
  ProductsProvider({
    required AuthProvider authProvider,
    required ProductService productService,
  })  : _authProvider = authProvider,
        _productService = productService {
    _authProvider.addListener(_handleAuthChanged);
    _handleAuthChanged();
  }

  final AuthProvider _authProvider;
  final ProductService _productService;

  StreamSubscription<List<Product>>? _subscription;
  List<Product> _products = const [];
  String _searchQuery = '';
  String? _categoryFilter;
  ProductFilter _productFilter = ProductFilter.all;
  bool _loading = false;
  String? _error;

  List<Product> get products => List.unmodifiable(_products);
  bool get isLoading => _loading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get categoryFilter => _categoryFilter;
  ProductFilter get productFilter => _productFilter;
  bool get hasProducts => _products.isNotEmpty;

  List<String> get categories {
    final values = _products.map((product) => product.category).toSet().toList();
    values.sort();
    return values;
  }

  List<Product> get filteredProducts {
    return _products.where((product) {
      final query = _searchQuery.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query) ||
          product.status.toLowerCase().contains(query);
      final matchesCategory =
          _categoryFilter == null || product.category == _categoryFilter;
      final matchesState =
          _productFilter == ProductFilter.all || product.isLowStock;
      return matchesQuery && matchesCategory && matchesState;
    }).toList();
  }

  List<Product> get lowStockProducts {
    return _products.where((product) => product.isLowStock).toList();
  }

  void updateSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void updateCategoryFilter(String? value) {
    _categoryFilter = value;
    notifyListeners();
  }

  void updateProductFilter(ProductFilter value) {
    _productFilter = value;
    notifyListeners();
  }

  Future<void> createProduct(Product product) async {
    final userId = _authProvider.user?.id;
    if (userId == null) {
      _error = 'Debes iniciar sesión para crear productos.';
      notifyListeners();
      return;
    }
    await _execute(() => _productService.createProduct(userId, product));
  }

  Future<void> updateProduct(Product product) async {
    final userId = _authProvider.user?.id;
    if (userId == null) {
      _error = 'Debes iniciar sesión para editar productos.';
      notifyListeners();
      return;
    }
    await _execute(() => _productService.updateProduct(userId, product));
  }

  Future<void> deleteProduct(String productId) async {
    final userId = _authProvider.user?.id;
    if (userId == null) {
      _error = 'Debes iniciar sesión para eliminar productos.';
      notifyListeners();
      return;
    }
    await _execute(() => _productService.deleteProduct(userId, productId));
  }

  Future<void> _execute(Future<void> Function() action) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } catch (error, stackTrace) {
      debugPrint('ProductsProvider._execute error: $error');
      debugPrint('$stackTrace');
      _error = 'No fue posible sincronizar los productos.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _handleAuthChanged() {
    debugPrint(
      'ProductsProvider._handleAuthChanged: user=${_authProvider.user?.id ?? 'null'}',
    );
    _subscription?.cancel();
    _products = const [];
    _error = null;
    final userId = _authProvider.user?.id;
    if (userId == null) {
      _loading = false;
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();
    _subscription = _productService.watchProducts(userId).listen(
      (items) {
        debugPrint(
          'ProductsProvider.watchProducts: received ${items.length} products',
        );
        _products = items;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('ProductsProvider.watchProducts error: $error');
        debugPrint('$stackTrace');
        _error = 'No fue posible cargar tus productos.';
        _loading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthChanged);
    _subscription?.cancel();
    super.dispose();
  }
}
