import 'package:stockmind/features/dashboard/data/models/stock_movement.dart';

enum AnalyticsTimeRange {
  today(1, 'Hoy'),
  last7Days(7, '7 días'),
  last30Days(30, '30 días'),
  last90Days(90, '90 días');

  const AnalyticsTimeRange(this.days, this.label);

  final int days;
  final String label;
}

enum ActivityInsightKind {
  movement,
  alert,
  request,
  product,
}

enum ActivityInsightPriority {
  high,
  medium,
  low,
}

class AnalyticsSeriesPoint {
  const AnalyticsSeriesPoint({
    required this.label,
    required this.value,
    this.secondaryValue = 0,
  });

  final String label;
  final double value;
  final double secondaryValue;
}

class AnalyticsBreakdownItem {
  const AnalyticsBreakdownItem({
    required this.label,
    required this.value,
    this.subtitle,
  });

  final String label;
  final double value;
  final String? subtitle;
}

class ActivityInsightItem {
  const ActivityInsightItem({
    required this.title,
    required this.subtitle,
    required this.when,
    required this.kind,
    required this.priority,
  });

  final String title;
  final String subtitle;
  final DateTime when;
  final ActivityInsightKind kind;
  final ActivityInsightPriority priority;
}

class DashboardAnalyticsSnapshot {
  const DashboardAnalyticsSnapshot({
    required this.range,
    required this.totalStock,
    required this.totalProducts,
    required this.criticalProducts,
    required this.expiredProducts,
    required this.activeLocations,
    required this.activeUsers,
    required this.pendingRequests,
    required this.activeAlerts,
    required this.movementsToday,
    required this.movementsInRange,
    required this.movementsWeek,
    required this.entriesInRange,
    required this.exitsInRange,
    required this.inventoryGrowthPercent,
    required this.movementDeltaPercent,
    required this.movementsByDay,
    required this.entriesVsExitsByDay,
    required this.weeklyTrend,
    required this.topMovedProducts,
    required this.stockByCategory,
    required this.alertsBySeverity,
    required this.activityItems,
  });

  final AnalyticsTimeRange range;
  final int totalStock;
  final int totalProducts;
  final int criticalProducts;
  final int expiredProducts;
  final int activeLocations;
  final int activeUsers;
  final int pendingRequests;
  final int activeAlerts;
  final int movementsToday;
  final int movementsInRange;
  final int movementsWeek;
  final int entriesInRange;
  final int exitsInRange;
  final double inventoryGrowthPercent;
  final double movementDeltaPercent;
  final List<AnalyticsSeriesPoint> movementsByDay;
  final List<AnalyticsSeriesPoint> entriesVsExitsByDay;
  final List<AnalyticsSeriesPoint> weeklyTrend;
  final List<AnalyticsBreakdownItem> topMovedProducts;
  final List<AnalyticsBreakdownItem> stockByCategory;
  final List<AnalyticsBreakdownItem> alertsBySeverity;
  final List<ActivityInsightItem> activityItems;

  bool get hasData =>
      totalProducts > 0 ||
      totalStock > 0 ||
      movementsInRange > 0 ||
      activeAlerts > 0 ||
      pendingRequests > 0;

  int get productsCriticalOrExpired => criticalProducts + expiredProducts;

  double get entryExitBalance => entriesInRange - exitsInRange.toDouble();

  double get stockCoverageScore {
    if (totalProducts == 0) return 100;
    final unhealthyRatio = productsCriticalOrExpired / totalProducts;
    return ((1 - unhealthyRatio) * 100).clamp(0, 100);
  }

  List<StockMovement> get emptyMovements => const [];

  static const empty = DashboardAnalyticsSnapshot(
    range: AnalyticsTimeRange.last7Days,
    totalStock: 0,
    totalProducts: 0,
    criticalProducts: 0,
    expiredProducts: 0,
    activeLocations: 0,
    activeUsers: 0,
    pendingRequests: 0,
    activeAlerts: 0,
    movementsToday: 0,
    movementsInRange: 0,
    movementsWeek: 0,
    entriesInRange: 0,
    exitsInRange: 0,
    inventoryGrowthPercent: 0,
    movementDeltaPercent: 0,
    movementsByDay: [],
    entriesVsExitsByDay: [],
    weeklyTrend: [],
    topMovedProducts: [],
    stockByCategory: [],
    alertsBySeverity: [],
    activityItems: [],
  );
}
