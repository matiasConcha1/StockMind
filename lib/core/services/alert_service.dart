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

  Stream<List<StockAlert>> watchAlerts(String companyId) {
    return _stockAlertService.watchAlerts(companyId);
  }

  Future<void> checkProductAlerts({
    required String companyId,
    required Product product,
  }) {
    return _stockAlertService.syncProductAlerts(companyId, product);
  }

  Future<void> checkAllProductAlerts({
    required String companyId,
    required Iterable<Product> products,
  }) {
    return _stockAlertService.syncAllProductAlerts(companyId, products);
  }

  Future<void> deleteAlertsForProduct(String companyId, String productId) {
    return _stockAlertService.deleteAlertsForProduct(companyId, productId);
  }

  Future<void> resolveProductAlerts({
    required String companyId,
    required String productId,
    required String resolvedBy,
  }) async {
    final activeAlerts =
        await _stockAlertService.getActiveAlertsForProduct(companyId, productId);
    await _stockAlertService.resolveActiveAlertsForProduct(
      companyId,
      productId,
      resolvedBy: resolvedBy,
    );
    for (final alert in activeAlerts) {
      try {
        await _activityLogService.createLog(
          companyId: companyId,
          action: 'resolve_alert',
          entityType: 'alert',
          entityId: alert.id,
          entityName: alert.productName,
          description:
              'Se resolvió la alerta ${alert.type} del producto ${alert.productName}.',
        );
      } catch (error, stackTrace) {
        debugPrint('AlertService.resolveProductAlerts log error: $error');
        debugPrint('$stackTrace');
      }
    }
  }

  Future<void> markAsRead(String companyId, String alertId) {
    return _stockAlertService.markAsRead(companyId, alertId);
  }

  Future<void> resolveAlert({
    required String companyId,
    required String alertId,
    required String resolvedBy,
  }) async {
    final alert = await _stockAlertService.getAlertById(companyId, alertId);
    await _stockAlertService.resolveAlert(
      companyId,
      alertId,
      resolvedBy: resolvedBy,
    );
    if (alert == null) return;
    try {
      await _activityLogService.createLog(
        companyId: companyId,
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
