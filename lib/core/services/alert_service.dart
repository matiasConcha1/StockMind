import 'package:flutter/foundation.dart';
import 'package:stockmind/features/activity_logs/data/services/activity_log_service.dart';
import 'package:stockmind/features/alerts/data/models/stock_alert.dart';
import 'package:stockmind/features/alerts/data/services/stock_alert_service.dart';
import 'package:stockmind/features/products/models/product.dart';

class AlertService {
  AlertService({
    StockAlertService? stockAlertService,
    ActivityLogService? activityLogService,
  })  : _stockAlertService = stockAlertService ?? StockAlertService(),
        _activityLogService = activityLogService ?? ActivityLogService();

  final StockAlertService _stockAlertService;
  final ActivityLogService _activityLogService;

  Stream<List<StockAlert>> watchAlerts(String userId) {
    return _stockAlertService.watchAlerts(userId);
  }

  Future<void> checkProductAlerts({
    required String userId,
    required Product product,
  }) {
    return _stockAlertService.syncProductAlerts(userId, product);
  }

  Future<void> checkAllProductAlerts({
    required String userId,
    required Iterable<Product> products,
  }) {
    return _stockAlertService.syncAllProductAlerts(userId, products);
  }

  Future<void> deleteAlertsForProduct(String userId, String productId) {
    return _stockAlertService.deleteAlertsForProduct(userId, productId);
  }

  Future<void> markAsRead(String userId, String alertId) {
    return _stockAlertService.markAsRead(userId, alertId);
  }

  Future<void> resolveAlert({
    required String userId,
    required String alertId,
    required String resolvedBy,
  }) async {
    final alert = await _stockAlertService.getAlertById(userId, alertId);
    await _stockAlertService.resolveAlert(
      userId,
      alertId,
      resolvedBy: resolvedBy,
    );
    if (alert == null) return;
    try {
      await _activityLogService.createLog(
        userId: userId,
        action: 'resolve_alert',
        entityType: 'alert',
        entityId: alert.id,
        entityName: alert.productName,
        description:
            'Se resolvió la alerta ${alert.type} del producto ${alert.productName}.',
      );
    } catch (error, stackTrace) {
      debugPrint('AlertService.resolveAlert log error: $error');
      debugPrint('$stackTrace');
    }
  }
}
