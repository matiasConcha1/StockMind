import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/core/theme/app_theme.dart';
import 'package:stockmind/core/widgets/empty_state.dart';
import 'package:stockmind/core/widgets/section_card.dart';
import 'package:stockmind/core/widgets/stat_card.dart';
import 'package:stockmind/core/widgets/stockmind_loading_screen.dart';
import 'package:stockmind/features/alerts/presentation/widgets/low_stock_list.dart';
import 'package:stockmind/features/alerts/providers/alerts_provider.dart';
import 'package:stockmind/features/dashboard/data/models/stock_movement.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/category_chart_card.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/dashboard_frame.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/inventory_movement_chart_card.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/recent_stock_movements_card.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/stock_bar_chart_card.dart';
import 'package:stockmind/features/dashboard/providers/dashboard_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final alertsProvider = context.watch<AlertsProvider>();
    final snapshot = provider.snapshot;
    final currency = NumberFormat.currency(symbol: '\$');
    final width = MediaQuery.sizeOf(context).width;
    final statCrossAxisCount = width < 720 ? 1 : width < 1180 ? 2 : 3;
    final movementPoints = _buildMovementPoints(snapshot.recentMovements);

    return DashboardFrame(
      title: 'Dashboard',
      subtitle:
          'Vista ejecutiva del inventario con estados inteligentes, alertas persistidas y movimientos recientes.',
      actions: [
        FilledButton.tonalIcon(
          onPressed: () {},
          icon: const Icon(Icons.download_rounded),
          label: const Text('Exportar'),
        ),
      ],
      child: Column(
        children: [
          if (provider.error != null) ...[
            _DashboardErrorBanner(message: provider.error!),
            const SizedBox(height: 16),
          ],
          if (provider.isLoading && !provider.hasProducts)
            const Card(
              child: SizedBox(
                height: 340,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: StockMindLoadingPanel(
                      compact: true,
                      statusMessage: 'Verificando sesión...',
                    ),
                  ),
                ),
              ),
            )
          else if (!provider.isLoading && !provider.hasProducts)
            const Card(
              child: SizedBox(
                height: 340,
                child: EmptyState(
                  title: 'Tu inventario está vacío',
                  subtitle:
                      'Agrega productos desde el módulo Productos para comenzar a ver métricas y alertas reales.',
                  icon: Icons.space_dashboard_outlined,
                ),
              ),
            )
          else ...[
            GridView.count(
              crossAxisCount: statCrossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.35,
              children: [
                StatCard(
                  label: 'Sin stock',
                  value: snapshot.outOfStockProducts.toString(),
                  helper: 'Productos que ya no tienen unidades',
                  icon: Icons.cancel_rounded,
                  color: AppTheme.danger,
                  trend: '${snapshot.activeAlerts} alertas activas',
                ),
                StatCard(
                  label: 'Bajo stock',
                  value: snapshot.lowStockProducts.toString(),
                  helper: 'Entre 1 y 4 unidades disponibles',
                  icon: Icons.warning_amber_rounded,
                  color: AppTheme.warning,
                  trend: '${snapshot.mediumStockProducts} en stock medio',
                ),
                StatCard(
                  label: 'Stock medio',
                  value: snapshot.mediumStockProducts.toString(),
                  helper: 'Entre 5 y 14 unidades disponibles',
                  icon: Icons.timeline_rounded,
                  color: const Color(0xFFEAB308),
                  trend: '${snapshot.highStockProducts} en stock alto',
                ),
                StatCard(
                  label: 'Stock alto',
                  value: snapshot.highStockProducts.toString(),
                  helper: '15 o más unidades disponibles',
                  icon: Icons.check_circle_outline_rounded,
                  color: AppTheme.success,
                  trend: '${snapshot.totalProducts} productos totales',
                ),
                StatCard(
                  label: 'Alertas activas',
                  value: snapshot.activeAlerts.toString(),
                  helper: 'Incidencias abiertas en Firebase',
                  icon: Icons.notifications_active_outlined,
                  color: AppTheme.brandViolet,
                  trend: '${alertsProvider.unreadAlertsCount} sin leer',
                ),
                StatCard(
                  label: 'Próximos a vencer',
                  value: snapshot.expiringSoonProducts.toString(),
                  helper: 'Vencen dentro de 15 días',
                  icon: Icons.event_available_outlined,
                  color: const Color(0xFFF97316),
                  trend: '${snapshot.expiredProducts} vencidos',
                ),
                StatCard(
                  label: 'Valor inventario',
                  value: currency.format(snapshot.totalInventoryValue),
                  helper: 'Capital comprometido',
                  icon: Icons.attach_money_rounded,
                  color: AppTheme.brand,
                  trend: '${snapshot.recentMovements.length} movimientos',
                ),
              ],
            ),
            const SizedBox(height: 16),
            SectionCard(
              gradient: LinearGradient(
                colors: [
                  AppTheme.brand.withValues(alpha: 0.16),
                  AppTheme.brandViolet.withValues(alpha: 0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ExecutiveKpi(
                      title: 'Stock health score',
                      value: '${snapshot.stockHealthScore.toStringAsFixed(0)}%',
                      helper: 'Cobertura saludable del catálogo',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ExecutiveKpi(
                      title: 'Alertas sin leer',
                      value: alertsProvider.unreadAlertsCount.toString(),
                      helper: 'Pendientes de revisión del equipo',
                    ),
                  ),
                  if (width > 920) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ExecutiveKpi(
                        title: 'Productos vencidos',
                        value: snapshot.expiredProducts.toString(),
                        helper: 'Requieren revisión inmediata',
                      ),
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.05, end: 0),
            const SizedBox(height: 16),
            if (width < 1100) ...[
              InventoryMovementChartCard(points: movementPoints),
              const SizedBox(height: 16),
              RecentStockMovementsCard(movements: snapshot.recentMovements),
              const SizedBox(height: 16),
              StockBarChartCard(products: snapshot.lowestStockProducts),
              const SizedBox(height: 16),
              CategoryChartCard(categories: snapshot.topCategories),
              const SizedBox(height: 16),
              LowStockList(
                alerts: alertsProvider.activeAlerts.take(6).toList(),
                onMarkAsRead: (alert) => alertsProvider.markAsRead(alert.id),
                onResolve: (alert) => alertsProvider.resolveAlert(alert.id),
              ),
            ] else
              Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: InventoryMovementChartCard(points: movementPoints),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: RecentStockMovementsCard(
                          movements: snapshot.recentMovements,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: LowStockList(
                          alerts: alertsProvider.activeAlerts.take(6).toList(),
                          onMarkAsRead: (alert) =>
                              alertsProvider.markAsRead(alert.id),
                          onResolve: (alert) =>
                              alertsProvider.resolveAlert(alert.id),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 7,
                        child: StockBarChartCard(
                          products: snapshot.lowestStockProducts,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CategoryChartCard(categories: snapshot.topCategories),
                ],
              ),
          ],
        ],
      ),
    );
  }

  List<InventoryMovementPoint> _buildMovementPoints(
    List<StockMovement> movements,
  ) {
    if (movements.isEmpty) return const [];

    final now = DateTime.now();
    final dailyTotals = <DateTime, int>{};
    for (var i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      dailyTotals[date] = 0;
    }

    for (final movement in movements) {
      final day = DateTime(
        movement.createdAt.year,
        movement.createdAt.month,
        movement.createdAt.day,
      );
      if (dailyTotals.containsKey(day)) {
        dailyTotals[day] = dailyTotals[day]! + movement.quantity;
      }
    }

    const labels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return dailyTotals.entries.map((entry) {
      final weekdayLabel = labels[entry.key.weekday - 1];
      return InventoryMovementPoint(
        label: weekdayLabel,
        value: entry.value.toDouble(),
      );
    }).toList();
  }
}

class _ExecutiveKpi extends StatelessWidget {
  const _ExecutiveKpi({
    required this.title,
    required this.value,
    required this.helper,
  });

  final String title;
  final String value;
  final String helper;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
          ),
        ),
        const SizedBox(height: 8),
        Text(value, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(helper, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _DashboardErrorBanner extends StatelessWidget {
  const _DashboardErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
