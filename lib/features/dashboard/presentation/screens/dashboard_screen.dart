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
import 'package:stockmind/features/alerts/presentation/widgets/low_stock_list.dart';
import 'package:stockmind/features/alerts/providers/alerts_provider.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
import 'package:stockmind/features/company/providers/company_profile_provider.dart';
import 'package:stockmind/features/dashboard/data/models/dashboard_snapshot.dart';
import 'package:stockmind/features/dashboard/data/models/stock_movement.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/category_chart_card.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/dashboard_frame.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/inventory_movement_chart_card.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/recent_stock_movements_card.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/activity_feed_card.dart';
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

    final heroGreeting =
        (userProvider.currentUser?.displayName ?? auth.user?.displayName ?? 'equipo')
            .split(' ')
            .first;

    return DashboardFrame(
      title: 'Hola, $heroGreeting',
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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: provider.isLoading && !provider.hasProducts
                ? const _DashboardSkeleton(key: ValueKey('dashboard-skeleton'))
                : !provider.isLoading && !provider.hasProducts
                    ? const SectionCard(
                        key: ValueKey('dashboard-empty'),
                        child: SizedBox(
                          height: 320,
                          child: EmptyState(
                            title: 'Tu inventario está vacío',
                            subtitle:
                                'Agrega productos para activar métricas, alertas y seguimiento operativo en tiempo real.',
                            icon: Icons.space_dashboard_outlined,
                            compact: true,
                          ),
                        ),
                      )
                    : _DashboardContent(
                        key: const ValueKey('dashboard-content'),
                        width: width,
                        isMobile: isMobile,
                        companyProvider: companyProvider,
                        snapshot: snapshot,
                        statCards: statCards,
                        movementPoints: movementPoints,
                        alertsProvider: alertsProvider,
                        requestsProvider: requestsProvider,
                        contextForRequest: context,
                      ),
          ),
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
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.width,
    required this.isMobile,
    required this.companyProvider,
    required this.snapshot,
    required this.statCards,
    required this.movementPoints,
    required this.alertsProvider,
    required this.requestsProvider,
    required this.contextForRequest,
    super.key,
  });

  final double width;
  final bool isMobile;
  final CompanyProfileProvider companyProvider;
  final DashboardSnapshot snapshot;
  final List<Widget> statCards;
  final List<InventoryMovementPoint> movementPoints;
  final AlertsProvider alertsProvider;
  final StockRequestsProvider requestsProvider;
  final BuildContext contextForRequest;

  @override
  Widget build(BuildContext context) {
    final statCrossAxisCount = width < 900 ? 1 : width < 1260 ? 2 : 3;
    final statAspectRatio = width >= 1260 ? 1.22 : width >= 900 ? 1.08 : 1.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OverviewHero(
          snapshot: snapshot,
          unreadAlerts: alertsProvider.unreadAlertsCount,
        ),
        const SizedBox(height: 16),
        if (!companyProvider.isComplete) ...[
          const _InlineSetupBanner(),
          const SizedBox(height: 16),
        ],
        _SectionTitle(
          title: 'Visión general',
          subtitle: 'Indicadores clave de inventario y operación.',
        ),
        const SizedBox(height: 12),
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
        _PremiumMetricBand(
          title: 'Salud operativa',
          subtitle: 'Cobertura, alertas y riesgo de vencimiento en una sola lectura.',
          isMobile: isMobile,
          children: [
            _ExecutiveKpi(
              title: 'Stock health score',
              value: '${snapshot.stockHealthScore.toStringAsFixed(0)}%',
              helper: 'Cobertura saludable del catálogo',
            ),
            _ExecutiveKpi(
              title: 'Alertas sin leer',
              value: alertsProvider.unreadAlertsCount.toString(),
              helper: 'Pendientes de revisión del equipo',
            ),
            _ExecutiveKpi(
              title: 'Productos vencidos',
              value: snapshot.expiredProducts.toString(),
              helper: 'Requieren revisión inmediata',
            ),
          ],
        ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.05, end: 0),
        const SizedBox(height: 16),
        _PremiumMetricBand(
          title: 'Flujo diario',
          subtitle: 'Movimiento, reposición y productos con mayor actividad.',
          isMobile: isMobile,
          trailing: snapshot.topMovedProductNames.isNotEmpty
              ? Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: snapshot.topMovedProductNames
                      .map((name) => _movementChip(context, name))
                      .toList(),
                )
              : null,
          children: [
            _ExecutiveKpi(
              title: 'Entradas hoy',
              value: '${snapshot.entriesToday}',
              helper: 'Unidades ingresadas hoy',
            ),
            _ExecutiveKpi(
              title: 'Salidas hoy',
              value: '${snapshot.exitsToday}',
              helper: 'Unidades retiradas hoy',
            ),
            _ExecutiveKpi(
              title: 'Solicitudes pendientes',
              value: '${snapshot.pendingRequests}',
              helper: 'Reposiciones esperando gestión',
            ),
            _ExecutiveKpi(
              title: 'Críticos sin solicitud',
              value: '${snapshot.criticalWithoutRequest}',
              helper: 'Stock bajo sin reposición',
            ),
          ],
        ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.05, end: 0),
        const SizedBox(height: 16),
        _InsightCard(
          title: 'Reposición',
          subtitle:
              'Solicitudes abiertas, completadas y productos que más reposición concentran esta semana.',
          isMobile: isMobile,
          leading: _ExecutiveKpi(
            title: 'Completadas esta semana',
            value: '${snapshot.completedRequestsThisWeek}',
            helper: 'Reposiciones cerradas recientemente',
          ),
          trailing: _LocationInsightBlock(
            title: 'Productos con más reposiciones',
            items: snapshot.productsWithMoreRequests,
          ),
        ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.05, end: 0),
        const SizedBox(height: 16),
        _InsightCard(
          title: 'Distribución por ubicación',
          subtitle:
              'Lectura rápida de zonas con menos stock, productos agotados y movimientos recientes.',
          isMobile: isMobile,
          leading: _LocationInsightBlock(
            title: 'Ubicaciones con menos stock',
            items: snapshot.lowStockLocations
                .map((item) => '${item.label} · ${item.quantity} unid.')
                .toList(),
          ),
          middle: _LocationInsightBlock(
            title: 'Agotados por ubicación',
            items: snapshot.outOfStockByLocation,
          ),
          trailing: _LocationInsightBlock(
            title: 'Movimientos por ubicación',
            items: snapshot.movementLocationNames,
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
          ActivityFeedCard(
            movements: snapshot.recentMovements,
            alerts: alertsProvider.activeAlerts,
            criticalProducts: snapshot.lowestStockProducts,
          ),
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
                contextForRequest,
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
              ActivityFeedCard(
                movements: snapshot.recentMovements,
                alerts: alertsProvider.activeAlerts,
                criticalProducts: snapshot.lowestStockProducts,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: LowStockList(
                      alerts: alertsProvider.activeAlerts.take(6).toList(),
                      onMarkAsRead: (alert) => alertsProvider.markAsRead(alert.id),
                      onResolve: (alert) => alertsProvider.resolveAlert(alert.id),
                      onCreateRequest: (alert) {
                        if (requestsProvider
                            .hasPendingRequestForProduct(alert.productId)) {
                          return;
                        }
                        showStockRequestDialog(
                          contextForRequest,
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
    );
  }

  Widget _movementChip(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.10)),
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

class _OverviewHero extends StatelessWidget {
  const _OverviewHero({
    required this.snapshot,
    required this.unreadAlerts,
  });

  final DashboardSnapshot snapshot;
  final int unreadAlerts;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      borderRadius: 30,
      gradient: LinearGradient(
        colors: [
          AppTheme.brand.withValues(alpha: 0.18),
          AppTheme.brandViolet.withValues(alpha: 0.12),
          Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 860;
          final metrics = [
            _HeroMetric(
              label: 'Movimientos',
              value: snapshot.recentMovements.length.toString(),
            ),
            _HeroMetric(
              label: 'Alertas sin leer',
              value: unreadAlerts.toString(),
            ),
            _HeroMetric(
              label: 'Cobertura',
              value: '${snapshot.stockHealthScore.toStringAsFixed(0)}%',
            ),
          ];
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _HeroHeading(),
                const SizedBox(height: 18),
                ...metrics.expand((item) => [item, const SizedBox(height: 12)]).toList()
                  ..removeLast(),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(flex: 5, child: _HeroHeading()),
              const SizedBox(width: 18),
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    for (final metric in metrics) ...[
                      metric,
                      const SizedBox(height: 12),
                    ],
                  ]..removeLast(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroHeading extends StatelessWidget {
  const _HeroHeading();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.54),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Panel ejecutivo',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Tu operación se ve más clara cuando el inventario respira bien.',
          style: theme.textTheme.headlineSmall?.copyWith(
            letterSpacing: -0.9,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Monitorea ritmo de stock, alertas activas y puntos críticos desde una vista preparada para decisiones rápidas.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.76),
          ),
        ),
      ],
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleMedium,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              letterSpacing: -0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumMetricBand extends StatelessWidget {
  const _PremiumMetricBand({
    required this.title,
    required this.subtitle,
    required this.isMobile,
    required this.children,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final bool isMobile;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      gradient: LinearGradient(
        colors: [
          AppTheme.brand.withValues(alpha: 0.12),
          AppTheme.brandViolet.withValues(alpha: 0.07),
          Theme.of(context).colorScheme.surface.withValues(alpha: 0.98),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: title, subtitle: subtitle, compact: true),
          const SizedBox(height: 16),
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final child in children) ...[
                  child,
                  const SizedBox(height: 16),
                ],
                if (trailing != null) trailing!,
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: children
                      .map(
                        (child) => SizedBox(
                          width: 220,
                          child: child,
                        ),
                      )
                      .toList(),
                ),
                if (trailing != null) ...[
                  const SizedBox(height: 18),
                  trailing!,
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.subtitle,
    required this.isMobile,
    required this.leading,
    this.middle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final bool isMobile;
  final Widget leading;
  final Widget? middle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final blocks = [
      leading,
      if (middle != null) middle!,
      if (trailing != null) trailing!,
    ];
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: title, subtitle: subtitle, compact: true),
          const SizedBox(height: 16),
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final block in blocks) ...[
                  block,
                  const SizedBox(height: 16),
                ],
              ]..removeLast(),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: blocks
                  .map(
                    (block) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: block,
                      ),
                    ),
                  )
                  .toList()
                ..removeLast()
                ..add(Expanded(child: blocks.last)),
            ),
        ],
      ),
    );
  }
}

class _InlineSetupBanner extends StatelessWidget {
  const _InlineSetupBanner();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      gradient: LinearGradient(
        colors: [
          AppTheme.brand.withValues(alpha: 0.12),
          AppTheme.brandViolet.withValues(alpha: 0.06),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personaliza tu espacio',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Completa el perfil de empresa desde Ajustes > Empresa para mostrar el nombre y logo de tu negocio en reportes y centro de inventario.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: compact ? theme.textTheme.titleLarge : theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
          ),
        ),
      ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(helper, style: theme.textTheme.bodyMedium),
        ],
      ),
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
                compact: true,
              ),
            )
          else
            ...products.map(
              (product) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.12),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: theme.colorScheme.primary,
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
            ),
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SkeletonBlock(height: 180, radius: 30),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width < 900 ? 1 : 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.18,
          children: List.generate(
            MediaQuery.sizeOf(context).width < 900 ? 3 : 6,
            (_) => const _SkeletonBlock(height: 160, radius: 28),
          ),
        ),
        const SizedBox(height: 16),
        const _SkeletonBlock(height: 220, radius: 28),
        const SizedBox(height: 16),
        const _SkeletonBlock(height: 220, radius: 28),
      ],
    );
  }
}

class _SkeletonBlock extends StatefulWidget {
  const _SkeletonBlock({
    required this.height,
    required this.radius,
  });

  final double height;
  final double radius;

  @override
  State<_SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<_SkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = 0.12 + (_controller.value * 0.08);
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.surfaceContainerHighest.withValues(alpha: pulse),
                theme.colorScheme.surfaceContainerHighest.withValues(alpha: pulse + 0.06),
                theme.colorScheme.surfaceContainerHighest.withValues(alpha: pulse),
              ],
            ),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
        );
      },
    );
  }
}

class _DashboardErrorBanner extends StatelessWidget {
  const _DashboardErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
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
    );
  }
}
