import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:stockmind/core/services/company_scope_service.dart';
import 'package:stockmind/features/alerts/data/models/stock_alert.dart';
import 'package:stockmind/features/dashboard/analytics/models/dashboard_analytics_snapshot.dart';
import 'package:stockmind/features/dashboard/data/models/stock_movement.dart';
import 'package:stockmind/features/products/models/product.dart';
import 'package:stockmind/features/replenishment/models/stock_request.dart';

class DashboardAnalyticsService {
  DashboardAnalyticsService({
    FirebaseFirestore? firestore,
    CompanyScopeService? scopeService,
  }) : _scopeService =
            scopeService ?? CompanyScopeService(firestore: firestore);

  final CompanyScopeService _scopeService;

  Stream<int> watchActiveUsers(String companyId) {
    return _scopeService
        .companyCollection(companyId, 'users')
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.where((doc) {
            final data = doc.data();
            return (data['isActive'] ?? true) == true;
          }).length,
        );
  }

  Stream<List<StockMovement>> watchAnalyticsMovements(
    String companyId, {
    required AnalyticsTimeRange maxRange,
  }) {
    final since = DateTime.now().subtract(Duration(days: maxRange.days - 1));
    return _scopeService
        .companyCollection(companyId, 'stock_movements')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('createdAt', descending: false)
        .limit(_movementLimitForRange(maxRange))
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(StockMovement.fromFirestore).toList(),
        );
  }

  DashboardAnalyticsSnapshot buildSnapshot({
    required AnalyticsTimeRange range,
    required List<Product> products,
    required List<StockMovement> movements,
    required List<StockAlert> alerts,
    required List<StockRequest> requests,
    required int locationsCount,
    required int activeUsers,
  }) {
    final now = DateTime.now();
    final start = _rangeStart(now, range);
    final previousStart = start.subtract(Duration(days: range.days));

    final rangeMovements = movements
        .where((item) => !item.createdAt.isBefore(start))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final previousRangeMovements = movements
        .where(
          (item) =>
              item.createdAt.isBefore(start) &&
              !item.createdAt.isBefore(previousStart),
        )
        .toList();

    final totalStock = products.fold<int>(0, (sum, item) => sum + item.totalStock);
    final criticalProducts = products.where((item) => item.isCriticalStock).length;
    final expiredProducts = products.where((item) => item.isExpired).length;
    final activeAlerts = alerts.where((item) => item.isActive).length;
    final pendingRequests = requests.where((item) => item.isPending).length;
    final entriesInRange = rangeMovements
        .where((item) => item.isEntry)
        .fold<int>(0, (sum, item) => sum + item.quantity);
    final exitsInRange = rangeMovements
        .where((item) => item.isExit || item.isExpired || item.isDamaged)
        .fold<int>(0, (sum, item) => sum + item.quantity);
    final netChange = _computeNetChange(rangeMovements);
    final openingStock = max(0, totalStock - netChange);
    final inventoryGrowthPercent =
        _computePercentDelta(current: totalStock, previous: openingStock);

    return DashboardAnalyticsSnapshot(
      range: range,
      totalStock: totalStock,
      totalProducts: products.length,
      criticalProducts: criticalProducts,
      expiredProducts: expiredProducts,
      activeLocations: locationsCount,
      activeUsers: activeUsers,
      pendingRequests: pendingRequests,
      activeAlerts: activeAlerts,
      movementsToday: movements
          .where((item) => _isSameDay(item.createdAt, now))
          .length,
      movementsInRange: rangeMovements.length,
      movementsWeek: movements
          .where(
            (item) =>
                !item.createdAt.isBefore(now.subtract(const Duration(days: 6))),
          )
          .length,
      entriesInRange: entriesInRange,
      exitsInRange: exitsInRange,
      inventoryGrowthPercent: inventoryGrowthPercent,
      movementDeltaPercent: _computePercentDelta(
        current: rangeMovements.length,
        previous: previousRangeMovements.length,
      ),
      movementsByDay: _buildMovementSeries(rangeMovements, range, now),
      entriesVsExitsByDay: _buildEntryExitSeries(rangeMovements, range, now),
      weeklyTrend: _buildWeeklyTrendSeries(rangeMovements, range, now),
      topMovedProducts: _buildTopMovedProducts(rangeMovements),
      stockByCategory: _buildStockByCategory(products),
      alertsBySeverity: _buildAlertSeverity(alerts),
      activityItems: _buildActivityItems(
        movements: rangeMovements,
        alerts: alerts,
        products: products,
        requests: requests,
      ),
    );
  }

  int _movementLimitForRange(AnalyticsTimeRange range) {
    switch (range) {
      case AnalyticsTimeRange.today:
        return 120;
      case AnalyticsTimeRange.last7Days:
        return 320;
      case AnalyticsTimeRange.last30Days:
        return 900;
      case AnalyticsTimeRange.last90Days:
        return 1800;
    }
  }

  DateTime _rangeStart(DateTime now, AnalyticsTimeRange range) {
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: range.days - 1));
  }

  int _computeNetChange(List<StockMovement> movements) {
    return movements.fold<int>(0, (sum, movement) {
      if (movement.isEntry) return sum + movement.quantity;
      if (movement.isExit || movement.isDamaged || movement.isExpired) {
        return sum - movement.quantity;
      }
      if (movement.isAdjustment) {
        return sum + (movement.newTotalStock - movement.previousTotalStock);
      }
      return sum;
    });
  }

  double _computePercentDelta({
    required num current,
    required num previous,
  }) {
    if (previous == 0) {
      return current == 0 ? 0 : 100;
    }
    return (((current - previous) / previous) * 100).clamp(-999, 999).toDouble();
  }

  List<AnalyticsSeriesPoint> _buildMovementSeries(
    List<StockMovement> movements,
    AnalyticsTimeRange range,
    DateTime now,
  ) {
    final formatter = range == AnalyticsTimeRange.today
        ? DateFormat('HH')
        : DateFormat(range == AnalyticsTimeRange.last90Days ? 'dd/MM' : 'EE');
    final buckets = <DateTime, double>{};
    final totalBuckets = range == AnalyticsTimeRange.today ? 8 : min(range.days, 14);
    final start = range == AnalyticsTimeRange.today
        ? DateTime(now.year, now.month, now.day, max(0, now.hour - 7))
        : DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: totalBuckets - 1));

    for (var i = 0; i < totalBuckets; i++) {
      final key = range == AnalyticsTimeRange.today
          ? DateTime(start.year, start.month, start.day, start.hour + i)
          : DateTime(start.year, start.month, start.day + i);
      buckets[key] = 0;
    }

    for (final movement in movements) {
      final bucket = range == AnalyticsTimeRange.today
          ? DateTime(
              movement.createdAt.year,
              movement.createdAt.month,
              movement.createdAt.day,
              movement.createdAt.hour,
            )
          : DateTime(
              movement.createdAt.year,
              movement.createdAt.month,
              movement.createdAt.day,
            );
      if (buckets.containsKey(bucket)) {
        buckets[bucket] = buckets[bucket]! + movement.quantity;
      }
    }

    return buckets.entries
        .map(
          (entry) => AnalyticsSeriesPoint(
            label: formatter.format(entry.key),
            value: entry.value,
          ),
        )
        .toList();
  }

  List<AnalyticsSeriesPoint> _buildEntryExitSeries(
    List<StockMovement> movements,
    AnalyticsTimeRange range,
    DateTime now,
  ) {
    final formatter = DateFormat(range == AnalyticsTimeRange.today ? 'HH' : 'dd/MM');
    final totalBuckets = range == AnalyticsTimeRange.today ? 8 : min(range.days, 10);
    final start = range == AnalyticsTimeRange.today
        ? DateTime(now.year, now.month, now.day, max(0, now.hour - 7))
        : DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: totalBuckets - 1));
    final buckets = <DateTime, List<double>>{};
    for (var i = 0; i < totalBuckets; i++) {
      final key = range == AnalyticsTimeRange.today
          ? DateTime(start.year, start.month, start.day, start.hour + i)
          : DateTime(start.year, start.month, start.day + i);
      buckets[key] = [0, 0];
    }
    for (final movement in movements) {
      final bucket = range == AnalyticsTimeRange.today
          ? DateTime(
              movement.createdAt.year,
              movement.createdAt.month,
              movement.createdAt.day,
              movement.createdAt.hour,
            )
          : DateTime(
              movement.createdAt.year,
              movement.createdAt.month,
              movement.createdAt.day,
            );
      if (!buckets.containsKey(bucket)) continue;
      if (movement.isEntry) {
        buckets[bucket]![0] += movement.quantity;
      }
      if (movement.isExit || movement.isExpired || movement.isDamaged) {
        buckets[bucket]![1] += movement.quantity;
      }
    }
    return buckets.entries
        .map(
          (entry) => AnalyticsSeriesPoint(
            label: formatter.format(entry.key),
            value: entry.value[0],
            secondaryValue: entry.value[1],
          ),
        )
        .toList();
  }

  List<AnalyticsSeriesPoint> _buildWeeklyTrendSeries(
    List<StockMovement> movements,
    AnalyticsTimeRange range,
    DateTime now,
  ) {
    final totalWeeks = range.days <= 7 ? 1 : min((range.days / 7).ceil(), 8);
    final buckets = <DateTime, double>{};
    final startWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: (totalWeeks - 1) * 7));
    for (var i = 0; i < totalWeeks; i++) {
      final date = startWeek.add(Duration(days: i * 7));
      buckets[date] = 0;
    }
    for (final movement in movements) {
      final daysDiff = DateTime(
        movement.createdAt.year,
        movement.createdAt.month,
        movement.createdAt.day,
      ).difference(startWeek).inDays;
      if (daysDiff < 0) continue;
      final bucketIndex = daysDiff ~/ 7;
      if (bucketIndex >= totalWeeks) continue;
      final bucket = startWeek.add(Duration(days: bucketIndex * 7));
      final delta = movement.isEntry
          ? movement.quantity
          : movement.isExit || movement.isExpired || movement.isDamaged
              ? -movement.quantity
              : movement.newTotalStock - movement.previousTotalStock;
      buckets[bucket] = buckets[bucket]! + delta.toDouble();
    }

    return buckets.entries
        .map(
          (entry) => AnalyticsSeriesPoint(
            label: 'S${((entry.key.difference(startWeek).inDays) ~/ 7) + 1}',
            value: entry.value,
          ),
        )
        .toList();
  }

  List<AnalyticsBreakdownItem> _buildTopMovedProducts(
    List<StockMovement> movements,
  ) {
    final values = <String, double>{};
    for (final movement in movements) {
      values.update(
        movement.productName,
        (value) => value + movement.quantity,
        ifAbsent: () => movement.quantity.toDouble(),
      );
    }
    return values.entries
        .map(
          (entry) => AnalyticsBreakdownItem(
            label: entry.key,
            value: entry.value,
            subtitle: '${entry.value.toInt()} unid.',
          ),
        )
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  List<AnalyticsBreakdownItem> _buildStockByCategory(List<Product> products) {
    final values = <String, double>{};
    for (final product in products) {
      values.update(
        product.category,
        (value) => value + product.totalStock,
        ifAbsent: () => product.totalStock.toDouble(),
      );
    }
    return values.entries
        .map(
          (entry) => AnalyticsBreakdownItem(
            label: entry.key,
            value: entry.value,
            subtitle: '${entry.value.toInt()} unid.',
          ),
        )
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  List<AnalyticsBreakdownItem> _buildAlertSeverity(List<StockAlert> alerts) {
    final values = <String, double>{
      'Crítica': 0,
      'Media': 0,
      'Informativa': 0,
    };
    for (final alert in alerts.where((item) => item.isActive)) {
      if (alert.isHigh) {
        values['Crítica'] = values['Crítica']! + 1;
      } else if (alert.isMedium) {
        values['Media'] = values['Media']! + 1;
      } else {
        values['Informativa'] = values['Informativa']! + 1;
      }
    }
    return values.entries
        .where((entry) => entry.value > 0)
        .map(
          (entry) => AnalyticsBreakdownItem(
            label: entry.key,
            value: entry.value,
            subtitle: '${entry.value.toInt()} alertas',
          ),
        )
        .toList();
  }

  List<ActivityInsightItem> _buildActivityItems({
    required List<StockMovement> movements,
    required List<StockAlert> alerts,
    required List<Product> products,
    required List<StockRequest> requests,
  }) {
    final items = <ActivityInsightItem>[
      ...movements.take(4).map(
            (item) => ActivityInsightItem(
              title: item.productName,
              subtitle:
                  '${item.isEntry ? 'Entrada' : item.isExit ? 'Salida' : 'Ajuste'} · ${item.quantity} unid. · ${item.reason}',
              when: item.createdAt,
              kind: ActivityInsightKind.movement,
              priority: item.isExit
                  ? ActivityInsightPriority.high
                  : ActivityInsightPriority.low,
            ),
          ),
      ...alerts.where((item) => item.isActive).take(4).map(
            (item) => ActivityInsightItem(
              title: item.title,
              subtitle: '${item.productName} · ${item.message}',
              when: item.updatedAt,
              kind: ActivityInsightKind.alert,
              priority: item.isHigh
                  ? ActivityInsightPriority.high
                  : item.isMedium
                      ? ActivityInsightPriority.medium
                      : ActivityInsightPriority.low,
            ),
          ),
      ...requests.where((item) => item.isPending).take(3).map(
            (item) => ActivityInsightItem(
              title: 'Solicitud pendiente',
              subtitle:
                  '${item.productName} · ${item.requestedQuantity} unid. · ${item.locationName}',
              when: item.updatedAt,
              kind: ActivityInsightKind.request,
              priority: ActivityInsightPriority.medium,
            ),
          ),
      ...products.where((item) => item.isAtRisk).take(3).map(
            (item) => ActivityInsightItem(
              title: item.isExpired ? 'Producto vencido' : 'Producto en riesgo',
              subtitle:
                  '${item.name} · ${item.totalStock} unid. · ${item.category}',
              when: item.updatedAt,
              kind: ActivityInsightKind.product,
              priority: item.isExpired
                  ? ActivityInsightPriority.high
                  : ActivityInsightPriority.medium,
            ),
          ),
    ]..sort((a, b) => b.when.compareTo(a.when));
    return items.take(8).toList();
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}
