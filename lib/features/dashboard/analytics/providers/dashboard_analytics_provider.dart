import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:stockmind/features/alerts/providers/alerts_provider.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
import 'package:stockmind/features/company/providers/current_company_provider.dart';
import 'package:stockmind/features/dashboard/analytics/models/dashboard_analytics_snapshot.dart';
import 'package:stockmind/features/dashboard/analytics/services/dashboard_analytics_service.dart';
import 'package:stockmind/features/dashboard/data/models/stock_movement.dart';
import 'package:stockmind/features/locations/providers/locations_provider.dart';
import 'package:stockmind/features/products/providers/products_provider.dart';
import 'package:stockmind/features/replenishment/providers/stock_requests_provider.dart';

class DashboardAnalyticsProvider extends ChangeNotifier {
  DashboardAnalyticsProvider({
    required AuthProvider authProvider,
    required CurrentCompanyProvider currentCompanyProvider,
    required ProductsProvider productsProvider,
    required LocationsProvider locationsProvider,
    required AlertsProvider alertsProvider,
    required StockRequestsProvider stockRequestsProvider,
    required DashboardAnalyticsService analyticsService,
  })  : _authProvider = authProvider,
        _currentCompanyProvider = currentCompanyProvider,
        _productsProvider = productsProvider,
        _locationsProvider = locationsProvider,
        _alertsProvider = alertsProvider,
        _stockRequestsProvider = stockRequestsProvider,
        _analyticsService = analyticsService {
    _authProvider.addListener(_handleAuthChanged);
    _currentCompanyProvider.addListener(_handleAuthChanged);
    _productsProvider.addListener(_syncSnapshot);
    _locationsProvider.addListener(_syncSnapshot);
    _alertsProvider.addListener(_syncSnapshot);
    _stockRequestsProvider.addListener(_syncSnapshot);
    _handleAuthChanged();
    _syncSnapshot();
  }

  final AuthProvider _authProvider;
  final CurrentCompanyProvider _currentCompanyProvider;
  final ProductsProvider _productsProvider;
  final LocationsProvider _locationsProvider;
  final AlertsProvider _alertsProvider;
  final StockRequestsProvider _stockRequestsProvider;
  final DashboardAnalyticsService _analyticsService;

  StreamSubscription<List<StockMovement>>? _movementSubscription;
  StreamSubscription<int>? _activeUsersSubscription;
  AnalyticsTimeRange _range = AnalyticsTimeRange.last7Days;
  DashboardAnalyticsSnapshot _snapshot = DashboardAnalyticsSnapshot.empty;
  List<StockMovement> _movements = const [];
  int _activeUsers = 0;
  bool _loading = false;
  String? _error;

  AnalyticsTimeRange get range => _range;
  DashboardAnalyticsSnapshot get snapshot => _snapshot;
  bool get isLoading =>
      _loading ||
      _productsProvider.isLoading ||
      _locationsProvider.isLoading ||
      _alertsProvider.isLoading ||
      _stockRequestsProvider.isLoading;
  String? get error =>
      _error ??
      _productsProvider.error ??
      _locationsProvider.error ??
      _alertsProvider.error ??
      _stockRequestsProvider.error;
  bool get hasData => _snapshot.hasData;

  void updateRange(AnalyticsTimeRange value) {
    if (_range == value) return;
    _range = value;
    _handleAuthChanged();
  }

  void _handleAuthChanged() {
    _movementSubscription?.cancel();
    _activeUsersSubscription?.cancel();
    _movements = const [];
    _activeUsers = 0;
    _error = null;

    final companyId = _currentCompanyProvider.companyId;
    if (!_authProvider.isAuthenticated || companyId == null) {
      _loading = false;
      _snapshot = DashboardAnalyticsSnapshot.empty;
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();
    _movementSubscription = _analyticsService
        .watchAnalyticsMovements(
          companyId,
          maxRange: AnalyticsTimeRange.last90Days,
        )
        .listen(
      (items) {
        _movements = items;
        _loading = false;
        _error = null;
        _syncSnapshot();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('DashboardAnalyticsProvider movements error: $error');
        debugPrint('$stackTrace');
        _movements = const [];
        _loading = false;
        _error = _friendlyError(error);
        _syncSnapshot();
      },
    );
    _activeUsersSubscription =
        _analyticsService.watchActiveUsers(companyId).listen(
      (count) {
        _activeUsers = count;
        _syncSnapshot();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('DashboardAnalyticsProvider users error: $error');
        debugPrint('$stackTrace');
        _activeUsers = 0;
        _error ??= _friendlyError(error);
        _syncSnapshot();
      },
    );
  }

  void _syncSnapshot() {
    _snapshot = _analyticsService.buildSnapshot(
      range: _range,
      products: _productsProvider.products,
      movements: _movements,
      alerts: _alertsProvider.activeAlerts,
      requests: _stockRequestsProvider.requests,
      locationsCount: _locationsProvider.locations.length,
      activeUsers: _activeUsers,
    );
    notifyListeners();
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    if (text.contains('permission-denied')) {
      return 'No tienes permisos suficientes para ver analytics de esta empresa.';
    }
    if (text.contains('unavailable')) {
      return 'Firestore está respondiendo lento. Mostramos los datos disponibles mientras reconectamos.';
    }
    return 'No fue posible cargar los analytics de movimientos.';
  }

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthChanged);
    _currentCompanyProvider.removeListener(_handleAuthChanged);
    _productsProvider.removeListener(_syncSnapshot);
    _locationsProvider.removeListener(_syncSnapshot);
    _alertsProvider.removeListener(_syncSnapshot);
    _stockRequestsProvider.removeListener(_syncSnapshot);
    _movementSubscription?.cancel();
    _activeUsersSubscription?.cancel();
    super.dispose();
  }
}
