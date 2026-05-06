import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/core/services/report_export_service.dart';
import 'package:stockmind/core/theme/app_theme.dart';
import 'package:stockmind/core/widgets/empty_state.dart';
import 'package:stockmind/core/widgets/export_feedback.dart';
import 'package:stockmind/core/widgets/section_card.dart';
import 'package:stockmind/core/widgets/stat_card.dart';
import 'package:stockmind/core/widgets/stockmind_loading_screen.dart';
import 'package:stockmind/features/alerts/presentation/widgets/low_stock_list.dart';
import 'package:stockmind/features/alerts/providers/alerts_provider.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
import 'package:stockmind/features/company/providers/company_profile_provider.dart';
import 'package:stockmind/features/dashboard/data/models/stock_movement.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/category_chart_card.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/dashboard_frame.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/inventory_movement_chart_card.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/recent_stock_movements_card.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/stock_bar_chart_card.dart';
import 'package:stockmind/features/dashboard/providers/dashboard_provider.dart';
import 'package:stockmind/features/products/models/product.dart';
import 'package:stockmind/features/products/providers/products_provider.dart';
import 'package:stockmind/features/replenishment/presentation/widgets/stock_request_dialog.dart';
import 'package:stockmind/features/replenishment/providers/stock_requests_provider.dart';
import 'package:stockmind/features/users/providers/user_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final auth = context.watch<AuthProvider>();
    final userProvider = context.watch<UserProvider>();
    final companyProvider = context.watch<CompanyProfileProvider>();
    final alertsProvider = context.watch<AlertsProvider>();
    final requestsProvider = context.watch<StockRequestsProvider>();
    final snapshot = provider.snapshot;
    final currency = NumberFormat.currency(symbol: '\$');
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 768;
    final statCrossAxisCount = width < 900 ? 1 : width < 1260 ? 2 : 3;
    final statAspectRatio = width >= 1260 ? 1.26 : width >= 900 ? 1.14 : 1.0;
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
      title:
          'Hola, ${(userProvider.currentUser?.displayName ?? auth.user?.displayName ?? 'equipo').split(' ').first} 👋',
      subtitle: companyProvider.isComplete
          ? 'Gestionando inventario de ${companyProvider.companyName}.'
          : 'Completa el perfil de empresa para personalizar tu operación en StockMind.',
      actions: [
        FilledButton.tonalIcon(
          onPressed: auth.canExport ? () => _exportInventory(context) : null,
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
            if (!companyProvider.isComplete) ...[
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personaliza tu espacio',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Completa el perfil de empresa desde Ajustes > Empresa para mostrar el nombre y logo de tu negocio en reportes y dashboard.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
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
                childAspectRatio: statAspectRatio,
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
            SectionCard(
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ExecutiveKpi(
                          title: 'Entradas hoy',
                          value: '${snapshot.entriesToday}',
                          helper: 'Unidades ingresadas hoy',
                        ),
                        const SizedBox(height: 16),
                        _ExecutiveKpi(
                          title: 'Salidas hoy',
                          value: '${snapshot.exitsToday}',
                          helper: 'Unidades retiradas hoy',
                        ),
                        const SizedBox(height: 16),
                        _ExecutiveKpi(
                          title: 'Solicitudes pendientes',
                          value: '${snapshot.pendingRequests}',
                          helper: 'Reposiciones esperando gestión',
                        ),
                        const SizedBox(height: 16),
                        _ExecutiveKpi(
                          title: 'Críticos sin solicitud',
                          value: '${snapshot.criticalWithoutRequest}',
                          helper: 'Productos con stock bajo sin reposición',
                        ),
                        if (snapshot.topMovedProductNames.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Productos con más movimientos',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: snapshot.topMovedProductNames
                                .map((name) => _movementChip(context, name))
                                .toList(),
                          ),
                        ],
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ExecutiveKpi(
                            title: 'Entradas hoy',
                            value: '${snapshot.entriesToday}',
                            helper: 'Unidades ingresadas hoy',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ExecutiveKpi(
                            title: 'Salidas hoy',
                            value: '${snapshot.exitsToday}',
                            helper: 'Unidades retiradas hoy',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ExecutiveKpi(
                            title: 'Solicitudes pendientes',
                            value: '${snapshot.pendingRequests}',
                            helper: 'Reposiciones esperando gestión',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ExecutiveKpi(
                            title: 'Críticos sin solicitud',
                            value: '${snapshot.criticalWithoutRequest}',
                            helper: 'Productos con stock bajo sin reposición',
                          ),
                        ),
                        if (snapshot.topMovedProductNames.isNotEmpty) ...[
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Productos con más movimientos',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: snapshot.topMovedProductNames
                                      .map((name) => _movementChip(context, name))
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
            ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.05, end: 0),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reposición',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Solicitudes abiertas, completadas y productos que más reposición concentran esta semana.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (isMobile)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ExecutiveKpi(
                          title: 'Completadas esta semana',
                          value: '${snapshot.completedRequestsThisWeek}',
                          helper: 'Reposiciones cerradas recientemente',
                        ),
                        const SizedBox(height: 16),
                        _LocationInsightBlock(
                          title: 'Productos con más reposiciones',
                          items: snapshot.productsWithMoreRequests,
                        ),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ExecutiveKpi(
                            title: 'Completadas esta semana',
                            value: '${snapshot.completedRequestsThisWeek}',
                            helper: 'Reposiciones cerradas recientemente',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: _LocationInsightBlock(
                            title: 'Productos con más reposiciones',
                            items: snapshot.productsWithMoreRequests,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.05, end: 0),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Distribución por ubicación',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Lectura rápida de ubicaciones con menos stock, productos agotados por ubicación y movimientos recientes por espacio.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (isMobile)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LocationInsightBlock(
                          title: 'Ubicaciones con menos stock',
                          items: snapshot.lowStockLocations
                              .map((item) => '${item.label} · ${item.quantity} unid.')
                              .toList(),
                        ),
                        const SizedBox(height: 14),
                        _LocationInsightBlock(
                          title: 'Agotados por ubicación',
                          items: snapshot.outOfStockByLocation,
                        ),
                        const SizedBox(height: 14),
                        _LocationInsightBlock(
                          title: 'Movimientos por ubicación',
                          items: snapshot.movementLocationNames,
                        ),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _LocationInsightBlock(
                            title: 'Ubicaciones con menos stock',
                            items: snapshot.lowStockLocations
                                .map((item) =>
                                    '${item.label} · ${item.quantity} unid.')
                                .toList(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _LocationInsightBlock(
                            title: 'Agotados por ubicación',
                            items: snapshot.outOfStockByLocation,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _LocationInsightBlock(
                            title: 'Movimientos por ubicación',
                            items: snapshot.movementLocationNames,
                          ),
                        ),
                      ],
                    ),
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
                onCreateRequest: (alert) {
                  if (requestsProvider.hasPendingRequestForProduct(alert.productId)) {
                    return;
                  }
                  showStockRequestDialog(
                    context,
                    initialProductId: alert.productId,
                  );
                },
                canCreateRequest: (alert) =>
                    !requestsProvider.hasPendingRequestForProduct(alert.productId),
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
                          onCreateRequest: (alert) {
                            if (requestsProvider
                                .hasPendingRequestForProduct(alert.productId)) {
                              return;
                            }
                            showStockRequestDialog(
                              context,
                              initialProductId: alert.productId,
                            );
                          },
                          canCreateRequest: (alert) => !requestsProvider
                              .hasPendingRequestForProduct(alert.productId),
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
    final auth = context.read<AuthProvider>();
    await runExportTask(
      context: context,
      hasData: products.isNotEmpty,
      noDataTitle: 'No hay datos para exportar',
      noDataMessage: 'Crea productos antes de generar un reporte.',
      successMessage: 'El inventario fue descargado correctamente.',
      task: () => ReportExportService().exportProductsCsv(
        products: products,
        userName: auth.user?.displayName ?? auth.user?.email,
        companyProfile: context.read<CompanyProfileProvider>().profile,
      ),
    );
    /*
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
    */
  }

  Widget _movementChip(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
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

class _LocationInsightBlock extends StatelessWidget {
  const _LocationInsightBlock({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        if (items.isEmpty)
          Text(
            'Sin datos todavía.',
            style: theme.textTheme.bodyMedium,
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item,
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                )
                .toList(),
          ),
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
