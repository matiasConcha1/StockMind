import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/core/theme/app_theme.dart';
import 'package:stockmind/core/widgets/app_alert_dialog.dart';
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
import 'package:stockmind/features/products/data/services/inventory_export_service.dart';
import 'package:stockmind/features/products/models/product.dart';
import 'package:stockmind/features/products/providers/products_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final alertsProvider = context.watch<AlertsProvider>();
    final snapshot = provider.snapshot;
    final currency = NumberFormat.currency(symbol: '\$');
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 768;
    final statCrossAxisCount = width < 720 ? 1 : width < 1180 ? 2 : 3;
    final movementPoints = _buildMovementPoints(snapshot.recentMovements);

    final statCards = [
      StatCard(
        label: 'Total productos',
        value: snapshot.totalProducts.toString(),
        helper: 'Catálogo sincronizado',
        icon: Icons.inventory_2_outlined,
        color: AppTheme.brand,
        trend: '${snapshot.totalUnits} unidades',
      ),
      StatCard(
        label: 'Stock bajo',
        value: snapshot.lowStockProducts.toString(),
        helper: '5 unidades o menos',
        icon: Icons.warning_amber_rounded,
        color: AppTheme.warning,
        trend: '${snapshot.activeAlerts} alertas activas',
      ),
      StatCard(
        label: 'Próximos a vencer',
        value: snapshot.expiringSoonProducts.toString(),
        helper: 'Vencen en 7 días',
        icon: Icons.event_available_outlined,
        color: const Color(0xFFF97316),
        trend: '${snapshot.expiredProducts} vencidos',
      ),
      StatCard(
        label: 'Ubicaciones',
        value: snapshot.totalLocations.toString(),
        helper: 'Espacios físicos registrados',
        icon: Icons.location_on_outlined,
        color: const Color(0xFF38BDF8),
        trend: '${snapshot.categories} categorías',
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
        label: 'Valor inventario',
        value: currency.format(snapshot.totalInventoryValue),
        helper: 'Capital comprometido',
        icon: Icons.attach_money_rounded,
        color: AppTheme.success,
        trend: '${snapshot.recentMovements.length} movimientos',
      ),
    ];

    return DashboardFrame(
      title: 'Dashboard',
      subtitle:
          'Vista ejecutiva del inventario con datos reales, alertas persistidas y movimientos recientes.',
      actions: [
        FilledButton.tonalIcon(
          onPressed: () => _exportInventory(context),
          icon: const Icon(Icons.download_rounded),
          label: const Text('Exportar'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final card in statCards) ...[
                    card,
                    const SizedBox(height: 14),
                  ],
                ],
              )
            else
              GridView.count(
                crossAxisCount: statCrossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.35,
                children: statCards,
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
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ExecutiveKpi(
                          title: 'Stock health score',
                          value: '${snapshot.stockHealthScore.toStringAsFixed(0)}%',
                          helper: 'Cobertura saludable del catálogo',
                        ),
                        const SizedBox(height: 16),
                        _ExecutiveKpi(
                          title: 'Alertas sin leer',
                          value: alertsProvider.unreadAlertsCount.toString(),
                          helper: 'Pendientes de revisión del equipo',
                        ),
                        const SizedBox(height: 16),
                        _ExecutiveKpi(
                          title: 'Productos vencidos',
                          value: snapshot.expiredProducts.toString(),
                          helper: 'Requieren revisión inmediata',
                        ),
                      ],
                    )
                  : Row(
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
              _RecentProductsCard(products: snapshot.recentlyUpdatedProducts),
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
                        child: _RecentProductsCard(
                          products: snapshot.recentlyUpdatedProducts,
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
                        child: RecentStockMovementsCard(
                          movements: snapshot.recentMovements,
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
                        child: CategoryChartCard(categories: snapshot.topCategories),
                      ),
                    ],
                  ),
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

  Future<void> _exportInventory(BuildContext context) async {
    final products = context.read<ProductsProvider>().products;
    if (products.isEmpty) {
      await showAppAlertDialog(
        context,
        type: AppAlertType.info,
        title: 'No hay datos para exportar',
        message: 'Crea productos antes de generar un reporte.',
      );
      return;
    }

    try {
      await InventoryExportService().exportProductsToCsv(products);
      if (!context.mounted) return;
      await showAppAlertDialog(
        context,
        type: AppAlertType.success,
        title: 'Reporte exportado',
        message: 'El inventario fue descargado correctamente.',
      );
    } catch (error) {
      if (!context.mounted) return;
      await showAppAlertDialog(
        context,
        type: AppAlertType.error,
        title: 'Error al exportar',
        message: error.toString().trim().isNotEmpty
            ? error.toString().trim()
            : 'No pudimos completar la exportación del inventario.',
      );
    }
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

class _RecentProductsCard extends StatelessWidget {
  const _RecentProductsCard({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Últimos productos actualizados', style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Actividad reciente del catálogo sincronizada desde Firestore.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (products.isEmpty)
            const SizedBox(
              height: 180,
              child: EmptyState(
                title: 'Sin actividad reciente',
                subtitle: 'Los últimos productos editados aparecerán aquí.',
                icon: Icons.inventory_2_outlined,
              ),
            )
          else
            ...products.map(
              (product) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(product.name),
                subtitle: Text(product.category),
                trailing: Text(
                  '${product.totalStock} unid.',
                  style: theme.textTheme.labelLarge,
                ),
              ),
            ),
        ],
      ),
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
