import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:stockmind/features/alerts/providers/alerts_provider.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
import 'package:stockmind/features/dashboard/data/models/dashboard_snapshot.dart';
import 'package:stockmind/features/dashboard/data/models/stock_movement.dart';
import 'package:stockmind/features/dashboard/data/services/stock_movement_service.dart';
import 'package:stockmind/features/dashboard/data/services/stock_service.dart';
import 'package:stockmind/features/products/models/product.dart';
import 'package:stockmind/features/products/providers/products_provider.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({
    required AuthProvider authProvider,
    required ProductsProvider productsProvider,
    required AlertsProvider alertsProvider,
    required StockService stockService,
    required StockMovementService stockMovementService,
  })  : _authProvider = authProvider,
        _productsProvider = productsProvider,
        _alertsProvider = alertsProvider,
        _stockService = stockService,
        _stockMovementService = stockMovementService {
    _authProvider.addListener(_handleAuthChanged);
    _productsProvider.addListener(_syncFromSources);
    _alertsProvider.addListener(_syncFromSources);
    _handleAuthChanged();
    _syncFromSources();
  }

  final AuthProvider _authProvider;
  final ProductsProvider _productsProvider;
  final AlertsProvider _alertsProvider;
  final StockService _stockService;
  final StockMovementService _stockMovementService;

  StreamSubscription<List<StockMovement>>? _movementSubscription;
  List<StockMovement> _recentMovements = const [];
  bool _movementsLoading = false;
  String? _movementError;

  DashboardSnapshot _snapshot = const DashboardSnapshot(
    totalProducts: 0,
    totalUnits: 0,
    outOfStockProducts: 0,
    lowStockProducts: 0,
    mediumStockProducts: 0,
    highStockProducts: 0,
    criticalProducts: 0,
    activeAlerts: 0,
    expiringSoonProducts: 0,
    expiredProducts: 0,
    categories: 0,
    totalInventoryValue: 0,
    topCategories: [],
    lowestStockProducts: [],
    recentMovements: [],
  );

  DashboardSnapshot get snapshot => _snapshot;
  List<Product> get lowStockProducts => _productsProvider.lowStockProducts;
  bool get isLoading => _productsProvider.isLoading || _movementsLoading;
  String? get error => _productsProvider.error ?? _movementError;
  bool get hasProducts => _productsProvider.hasProducts;

  void _handleAuthChanged() {
    debugPrint(
      'DashboardProvider._handleAuthChanged: user=${_authProvider.user?.id ?? 'null'}',
    );
    _movementSubscription?.cancel();
    _recentMovements = const [];
    _movementError = null;

    final userId = _authProvider.user?.id;
    if (userId == null) {
      _movementsLoading = false;
      _syncFromSources();
      return;
    }

    _movementsLoading = true;
    _syncFromSources();
    _movementSubscription = _stockMovementService.watchRecentMovements(userId).listen(
      (movements) {
        debugPrint(
          'DashboardProvider.watchRecentMovements: received ${movements.length} movements',
        );
        _recentMovements = movements;
        _movementsLoading = false;
        _movementError = null;
        _syncFromSources();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('DashboardProvider.watchRecentMovements error: $error');
        debugPrint('$stackTrace');
        _recentMovements = const [];
        _movementsLoading = false;
        _movementError = 'No fue posible cargar los movimientos de stock.';
        _syncFromSources();
      },
    );
  }

  void _syncFromSources() {
    _snapshot = _stockService.buildSnapshot(
      _productsProvider.products,
      _recentMovements,
      _alertsProvider.activeAlertsCount,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthChanged);
    _productsProvider.removeListener(_syncFromSources);
    _alertsProvider.removeListener(_syncFromSources);
    _movementSubscription?.cancel();
    super.dispose();
  }
}
