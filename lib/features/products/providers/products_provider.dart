import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:stockmind/core/services/alert_service.dart';
import 'package:stockmind/core/services/storage_service.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
import 'package:stockmind/features/company/providers/current_company_provider.dart';
import 'package:stockmind/features/products/data/services/product_service.dart';
import 'package:stockmind/features/products/models/product.dart';

enum ProductFilter { all, atRisk, optimal }

class ProductsProvider extends ChangeNotifier {
  ProductsProvider({
    required AuthProvider authProvider,
    required CurrentCompanyProvider currentCompanyProvider,
    required ProductService productService,
    required StorageService storageService,
    required AlertService alertService,
  })  : _authProvider = authProvider,
        _currentCompanyProvider = currentCompanyProvider,
        _productService = productService,
        _storageService = storageService,
        _alertService = alertService {
    _authProvider.addListener(_handleAuthChanged);
    _currentCompanyProvider.addListener(_handleAuthChanged);
    _handleAuthChanged();
  }

  final AuthProvider _authProvider;
  final CurrentCompanyProvider _currentCompanyProvider;
  final ProductService _productService;
  final StorageService _storageService;
  final AlertService _alertService;

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
          product.status.toLowerCase().contains(query) ||
          product.stockStatus.label.toLowerCase().contains(query) ||
          product.operationalStatusLabel.toLowerCase().contains(query);
      final matchesCategory =
          _categoryFilter == null || product.category == _categoryFilter;
      final matchesState = switch (_productFilter) {
        ProductFilter.all => true,
        ProductFilter.atRisk => product.isAtRisk,
        ProductFilter.optimal => product.isOptimal,
      };
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

  Future<void> createProduct(
    Product product, {
    PickedImageFile? imageFile,
  }) async {
    final userId = _authProvider.user?.id;
    final companyId = _currentCompanyProvider.companyId;
    debugPrint(
      'ProductsProvider.createProduct: companyId=${companyId ?? 'null'} name=${product.name}',
    );
    if (userId == null || companyId == null) {
      _error = 'Debes iniciar sesión para crear productos.';
      notifyListeners();
      return;
    }
    if (!_authProvider.canManageCatalog) {
      _error = 'No tienes permisos para crear productos.';
      notifyListeners();
      return;
    }
    await _execute(() async {
      final productId = product.id.isEmpty
          ? _productService.createProductId(companyId)
          : product.id;
      String? imageUrl = product.imageUrl;
      if (imageFile != null) {
        imageUrl = await _storageService.uploadProductImage(
          uid: userId,
          productId: productId,
          file: imageFile,
        );
      }
      final productToCreate =
          product.copyWith(id: productId, imageUrl: imageUrl);
      await _productService.createProduct(
        companyId,
        productToCreate,
      );
      await _syncProductAlertBestEffort(companyId, productToCreate);
    });
  }

  Future<void> updateProduct(
    Product product, {
    String? stockChangeReason,
    PickedImageFile? imageFile,
    bool removeImage = false,
  }) async {
    final userId = _authProvider.user?.id;
    final companyId = _currentCompanyProvider.companyId;
    debugPrint(
      'ProductsProvider.updateProduct: companyId=${companyId ?? 'null'} productId=${product.id}',
    );
    if (userId == null || companyId == null) {
      _error = 'Debes iniciar sesión para editar productos.';
      notifyListeners();
      return;
    }
    if (!_authProvider.canManageCatalog) {
      _error = 'No tienes permisos para editar productos.';
      notifyListeners();
      return;
    }
    Product? previousProduct;
    for (final item in _products) {
      if (item.id == product.id) {
        previousProduct = item;
        break;
      }
    }
    await _execute(() async {
      String? imageUrl = product.imageUrl;
      if (removeImage) {
        await _storageService.deleteImageByUrl(previousProduct?.imageUrl);
        imageUrl = null;
      }
      if (imageFile != null) {
        imageUrl = await _storageService.uploadProductImage(
          uid: userId,
          productId: product.id,
          file: imageFile,
        );
      }
      final productToUpdate = product.copyWith(imageUrl: imageUrl);
      await _productService.updateProduct(
        companyId,
        productToUpdate,
        previousProduct: previousProduct,
        stockChangeReason: stockChangeReason,
        actorUserId: _authProvider.user?.id,
        actorUserName: _authProvider.user?.displayName,
      );
      await _syncProductAlertBestEffort(companyId, productToUpdate);
    });
  }

  Future<void> deleteProduct(String productId) async {
    final userId = _authProvider.user?.id;
    final companyId = _currentCompanyProvider.companyId;
    debugPrint(
      'ProductsProvider.deleteProduct: companyId=${companyId ?? 'null'} productId=$productId',
    );
    if (userId == null || companyId == null) {
      _error = 'Debes iniciar sesión para eliminar productos.';
      notifyListeners();
      return;
    }
    if (!_authProvider.canDelete) {
      _error = 'Solo un administrador puede archivar productos.';
      notifyListeners();
      return;
    }
    Product? previous;
    for (final item in _products) {
      if (item.id == productId) {
        previous = item;
        break;
      }
    }
    await _execute(() async {
      if (previous == null) {
        throw StateError('No encontramos el producto que intentas archivar.');
      }
      await _productService.archiveProduct(
        userId: userId,
        companyId: companyId,
        product: previous,
        deletedBy: userId,
        deleteReason: 'manual',
      );
      await _resolveProductAlertsBestEffort(companyId, productId, userId);
    });
  }

  Future<ProductLookupResult?> findProductByCode(String code) async {
    final companyId = _currentCompanyProvider.companyId;
    if (companyId == null) {
      _error = 'Debes iniciar sesión para escanear productos.';
      notifyListeners();
      return null;
    }

    if (!_authProvider.canManageInventory) {
      _error = 'No tienes permisos para escanear productos.';
      notifyListeners();
      return null;
    }

    try {
      _error = null;
      notifyListeners();
      return await _productService.findProductByCode(companyId, code);
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        'ProductsProvider.findProductByCode FirebaseException: code=${error.code} message=${error.message}',
      );
      debugPrint('$stackTrace');
      _error = _mapFirebaseError(error);
      notifyListeners();
      return null;
    } catch (error, stackTrace) {
      debugPrint('ProductsProvider.findProductByCode error: $error');
      debugPrint('$stackTrace');
      _error = 'No fue posible buscar el producto escaneado.';
      notifyListeners();
      return null;
    }
  }

  Future<bool> adjustProductStock({
    required String productId,
    required String locationId,
    required String locationName,
    required int quantity,
    required bool increase,
  }) async {
    final companyId = _currentCompanyProvider.companyId;
    if (companyId == null) {
      _error = 'Debes iniciar sesión para actualizar el stock.';
      notifyListeners();
      return false;
    }

    if (!_authProvider.canManageInventory) {
      _error = 'No tienes permisos para registrar movimientos de stock.';
      notifyListeners();
      return false;
    }

    var success = false;
    await _execute(() async {
      final result = await _productService.adjustProductStock(
        companyId: companyId,
        productId: productId,
        locationId: locationId,
        locationName: locationName,
        quantity: quantity,
        increase: increase,
        movementType: increase ? 'entry' : 'exit',
        reason: increase
            ? 'Entrada rápida desde escáner'
            : 'Salida rápida desde escáner',
        actorUserId: _authProvider.user?.id,
        actorUserName: _authProvider.user?.displayName,
      );
      await _syncProductAlertBestEffort(companyId, result.product);
      success = true;
    });
    return success && _error == null;
  }

  Future<bool> setProductLocationStock({
    required String productId,
    required String locationId,
    required String locationName,
    required int quantity,
  }) async {
    final companyId = _currentCompanyProvider.companyId;
    if (companyId == null) {
      _error = 'Debes iniciar sesión para actualizar el stock.';
      notifyListeners();
      return false;
    }

    if (!_authProvider.canManageInventory) {
      _error = 'No tienes permisos para registrar movimientos de stock.';
      notifyListeners();
      return false;
    }

    var success = false;
    await _execute(() async {
      final result = await _productService.setProductLocationStock(
        companyId: companyId,
        productId: productId,
        locationId: locationId,
        locationName: locationName,
        newQuantity: quantity,
        reason: 'Ajuste rápido desde escáner',
        actorUserId: _authProvider.user?.id,
        actorUserName: _authProvider.user?.displayName,
      );
      await _syncProductAlertBestEffort(companyId, result.product);
      success = true;
    });
    return success && _error == null;
  }

  Future<bool> transferProductStock({
    required String productId,
    required String sourceLocationId,
    required String sourceLocationName,
    required String targetLocationId,
    required String targetLocationName,
    required int quantity,
  }) async {
    final companyId = _currentCompanyProvider.companyId;
    if (companyId == null) {
      _error = 'Debes iniciar sesión para actualizar el stock.';
      notifyListeners();
      return false;
    }

    if (!_authProvider.canManageInventory) {
      _error = 'No tienes permisos para transferir stock.';
      notifyListeners();
      return false;
    }

    var success = false;
    await _execute(() async {
      final result = await _productService.transferProductStock(
        companyId: companyId,
        productId: productId,
        sourceLocationId: sourceLocationId,
        sourceLocationName: sourceLocationName,
        targetLocationId: targetLocationId,
        targetLocationName: targetLocationName,
        quantity: quantity,
        actorUserId: _authProvider.user?.id,
        actorUserName: _authProvider.user?.displayName,
      );
      await _syncProductAlertBestEffort(companyId, result.product);
      success = true;
    });
    return success && _error == null;
  }

  Future<void> _execute(Future<void> Function() action) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        'ProductsProvider._execute FirebaseException: code=${error.code} message=${error.message}',
      );
      debugPrint('$stackTrace');
      _error = _mapFirebaseError(error);
    } on StorageServiceException catch (error, stackTrace) {
      debugPrint('ProductsProvider._execute storage error: ${error.message}');
      debugPrint('$stackTrace');
      _error = error.message;
    } catch (error, stackTrace) {
      debugPrint('ProductsProvider._execute error: $error');
      debugPrint('$stackTrace');
      _error = 'No fue posible sincronizar los productos.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _syncProductAlertBestEffort(String companyId, Product product) async {
    try {
      await _alertService.checkProductAlerts(
        companyId: companyId,
        product: product,
      );
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        'ProductsProvider._syncProductAlertBestEffort FirebaseException: code=${error.code} message=${error.message}',
      );
      debugPrint('$stackTrace');
    } catch (error, stackTrace) {
      debugPrint('ProductsProvider._syncProductAlertBestEffort error: $error');
      debugPrint('$stackTrace');
    }
  }

  void _handleAuthChanged() {
    debugPrint(
      'ProductsProvider._handleAuthChanged: user=${_authProvider.user?.id ?? 'null'}',
    );
    _subscription?.cancel();
    _products = const [];
    _error = null;
    final companyId = _currentCompanyProvider.companyId;
    if (companyId == null) {
      _loading = false;
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();
    _subscription = _productService.watchProducts(companyId).listen(
      (items) {
        debugPrint(
          'ProductsProvider.watchProducts: received ${items.length} products',
        );
        _products = items;
        _loading = false;
        _error = null;
        notifyListeners();
        unawaited(_syncAlertsForSnapshot(companyId, items));
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

  Future<void> _syncAlertsForSnapshot(
    String companyId,
    List<Product> items,
  ) async {
    for (final product in items) {
      await _ensureCodesBestEffort(companyId, product);
    }
    try {
      await _alertService.checkAllProductAlerts(
        companyId: companyId,
        products: items,
      );
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        'ProductsProvider._syncAlertsForSnapshot FirebaseException: code=${error.code} message=${error.message}',
      );
      debugPrint('$stackTrace');
    } catch (error, stackTrace) {
      debugPrint('ProductsProvider._syncAlertsForSnapshot error: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<void> _resolveProductAlertsBestEffort(
    String companyId,
    String productId,
    String resolvedBy,
  ) async {
    try {
      await _alertService.resolveProductAlerts(
        companyId: companyId,
        productId: productId,
        resolvedBy: resolvedBy,
      );
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        'ProductsProvider._resolveProductAlertsBestEffort FirebaseException: code=${error.code} message=${error.message}',
      );
      debugPrint('$stackTrace');
    } catch (error, stackTrace) {
      debugPrint('ProductsProvider._resolveProductAlertsBestEffort error: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<void> _ensureCodesBestEffort(String companyId, Product product) async {
    try {
      await _productService.ensureProductCodes(companyId, product);
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        'ProductsProvider._ensureCodesBestEffort FirebaseException: code=${error.code} message=${error.message}',
      );
      debugPrint('$stackTrace');
    } catch (error, stackTrace) {
      debugPrint('ProductsProvider._ensureCodesBestEffort error: $error');
      debugPrint('$stackTrace');
    }
  }

  String _mapFirebaseError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'No tienes permisos para guardar esta información. Revisa las reglas de Firestore.';
      case 'unavailable':
        return 'Firebase no está disponible en este momento. Intenta nuevamente.';
      case 'not-found':
        return 'No encontramos el recurso solicitado en Firestore.';
      case 'already-exists':
        return 'Ya existe otro producto con ese código. Usa uno diferente.';
      case 'failed-precondition':
        return 'Firestore requiere una configuración adicional para completar la operación.';
      default:
        return error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Ocurrió un error inesperado al guardar.';
    }
  }

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthChanged);
    _currentCompanyProvider.removeListener(_handleAuthChanged);
    _subscription?.cancel();
    super.dispose();
  }
}
