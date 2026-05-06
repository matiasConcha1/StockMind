import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:stockmind/core/services/alert_service.dart';
import 'package:stockmind/features/alerts/data/models/stock_alert.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';

enum AlertsFilter {
  all,
  lowStock,
  expiringSoon,
  expired,
  active,
  resolved,
}

class AlertsProvider extends ChangeNotifier {
  AlertsProvider({
    required AuthProvider authProvider,
    required AlertService alertService,
  })  : _authProvider = authProvider,
        _alertService = alertService {
    _authProvider.addListener(_handleAuthChanged);
    _handleAuthChanged();
  }

  final AuthProvider _authProvider;
  final AlertService _alertService;

  StreamSubscription<List<StockAlert>>? _subscription;
  List<StockAlert> _alerts = const [];
  AlertsFilter _filter = AlertsFilter.all;
  bool _loading = false;
  String? _error;

  List<StockAlert> get alerts => List.unmodifiable(_alerts);
  AlertsFilter get filter => _filter;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get hasAlerts => _alerts.isNotEmpty;
  bool get hasActiveAlerts => activeAlerts.isNotEmpty;

  List<StockAlert> get visibleAlerts {
    return switch (_filter) {
      AlertsFilter.all => _alerts,
      AlertsFilter.lowStock =>
        _alerts.where((alert) => alert.isActive && alert.isLowStock).toList(),
      AlertsFilter.expiringSoon =>
        _alerts.where((alert) => alert.isActive && alert.isExpiringSoon).toList(),
      AlertsFilter.expired =>
        _alerts.where((alert) => alert.isActive && alert.isExpired).toList(),
      AlertsFilter.active =>
        _alerts.where((alert) => alert.isActive).toList(),
      AlertsFilter.resolved =>
        _alerts.where((alert) => alert.isResolved).toList(),
    };
  }

  List<StockAlert> get activeAlerts =>
      _alerts.where((alert) => alert.isActive).toList();

  int get activeAlertsCount => activeAlerts.length;
  int get lowStockAlertsCount =>
      activeAlerts.where((alert) => alert.isLowStock).length;
  int get expiringSoonAlertsCount =>
      activeAlerts.where((alert) => alert.isExpiringSoon).length;
  int get expiredAlertsCount =>
      activeAlerts.where((alert) => alert.isExpired).length;
  int get resolvedAlertsCount =>
      _alerts.where((alert) => alert.isResolved).length;
  int get unreadAlertsCount =>
      activeAlerts.where((alert) => !alert.isRead).length;

  void updateFilter(AlertsFilter value) {
    _filter = value;
    notifyListeners();
  }

  Future<void> markAsRead(String alertId) async {
    final userId = _authProvider.user?.id;
    if (userId == null) return;
    await _runAction(() => _alertService.markAsRead(userId, alertId));
  }

  Future<void> resolveAlert(String alertId) async {
    final userId = _authProvider.user?.id;
    if (userId == null) return;
    await _runAction(
      () => _alertService.resolveAlert(
        userId: userId,
        alertId: alertId,
        resolvedBy: userId,
      ),
    );
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      debugPrint('AlertsProvider action error: $error');
      debugPrint('$stackTrace');
      _error = 'No fue posible actualizar la alerta.';
      notifyListeners();
    }
  }

  void _handleAuthChanged() {
    _subscription?.cancel();
    _alerts = const [];
    _error = null;

    final userId = _authProvider.user?.id;
    if (userId == null) {
      _loading = false;
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();
    _subscription = _alertService.watchAlerts(userId).listen(
      (items) {
        _alerts = items;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('AlertsProvider.watchAlerts error: $error');
        debugPrint('$stackTrace');
        _alerts = const [];
        _loading = false;
        _error = 'No fue posible cargar las alertas.';
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
