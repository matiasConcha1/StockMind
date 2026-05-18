import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/app/routes.dart';
import 'package:stockmind/core/services/report_export_service.dart';
import 'package:stockmind/core/theme/app_theme.dart';
import 'package:stockmind/core/widgets/empty_state.dart';
import 'package:stockmind/core/widgets/export_feedback.dart';
import 'package:stockmind/core/widgets/section_card.dart';
import 'package:stockmind/features/alerts/presentation/widgets/low_stock_list.dart';
import 'package:stockmind/features/alerts/providers/alerts_provider.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
import 'package:stockmind/features/company/providers/company_profile_provider.dart';
import 'package:stockmind/features/company/providers/current_company_provider.dart';
import 'package:stockmind/features/dashboard/analytics/models/dashboard_analytics_snapshot.dart';
import 'package:stockmind/features/dashboard/analytics/providers/dashboard_analytics_provider.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/activity_feed_card.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/analytics_bar_chart_card.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/analytics_donut_chart_card.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/analytics_filter_bar.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/analytics_kpi_card.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/analytics_line_chart_card.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/analytics_ranked_list_card.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/dashboard_frame.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/demo_tour_card.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/onboarding_checklist_card.dart';
import 'package:stockmind/features/products/providers/products_provider.dart';
import 'package:stockmind/features/replenishment/presentation/widgets/stock_request_dialog.dart';
import 'package:stockmind/features/replenishment/providers/stock_requests_provider.dart';
import 'package:stockmind/features/users/providers/user_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardAnalyticsProvider>();
    final auth = context.watch<AuthProvider>();
    final userProvider = context.watch<UserProvider>();
    final companyProvider = context.watch<CompanyProfileProvider>();
    final currentCompany = context.watch<CurrentCompanyProvider>();
    final alertsProvider = context.watch<AlertsProvider>();
    final requestsProvider = context.watch<StockRequestsProvider>();
    final snapshot = provider.snapshot;
    final width = MediaQuery.sizeOf(context).width;
    final isPersonalWorkspace =
        currentCompany.company?.isPersonalWorkspace == true;
    final heroGreeting =
        (userProvider.currentUser?.displayName ?? auth.user?.displayName ?? 'equipo')
            .split(' ')
            .first;
    final canExport = currentCompany.canExport;

    return DashboardFrame(
      title: isPersonalWorkspace ? 'Inventario personal' : 'Centro de inventario',
      subtitle: companyProvider.isComplete
          ? 'Rendimiento operativo de ${companyProvider.companyName} con señales reales de stock, alertas y colaboración.'
          : 'Activa un centro de analytics más claro mientras terminas de configurar tu espacio de trabajo.',
      actions: [
        FilledButton.tonalIcon(
          onPressed: canExport ? () => _exportInventory(context) : null,
          icon: const Icon(Icons.download_rounded),
          label: const Text('Exportar'),
        ),
      ],
      child: _buildBody(
        context,
        provider: provider,
        currentCompany: currentCompany,
        companyProvider: companyProvider,
        alertsProvider: alertsProvider,
        requestsProvider: requestsProvider,
        snapshot: snapshot,
        width: width,
        heroGreeting: heroGreeting,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required DashboardAnalyticsProvider provider,
    required CurrentCompanyProvider currentCompany,
    required CompanyProfileProvider companyProvider,
    required AlertsProvider alertsProvider,
    required StockRequestsProvider requestsProvider,
    required DashboardAnalyticsSnapshot snapshot,
    required double width,
    required String heroGreeting,
  }) {
    if (currentCompany.isLoading) {
      return const _DashboardAnalyticsSkeleton();
    }

    if (currentCompany.errorMessage != null && !currentCompany.hasCompany) {
      return _DashboardCompanyState(
        title: 'No pudimos cargar tu espacio activo',
        subtitle: currentCompany.errorMessage!,
        icon: Icons.error_outline_rounded,
        primaryLabel: 'Reintentar',
        onPrimaryAction: currentCompany.refresh,
        secondaryLabel: 'Crear espacio',
        onSecondaryAction: () => context.go(AppRoutePaths.workspaceSetup),
      );
    }

    if (!currentCompany.hasCompany || !currentCompany.hasAcceptedMembership) {
      return _DashboardCompanyState(
        title: 'Sin espacio de trabajo activo',
        subtitle:
            'Crea o selecciona un espacio de trabajo para cargar analytics, inventario e invitaciones.',
        icon: Icons.business_center_outlined,
        primaryLabel: 'Crear espacio de trabajo',
        onPrimaryAction: () => context.go(AppRoutePaths.workspaceSetup),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AnalyticsHero(
          greeting: heroGreeting,
          snapshot: snapshot,
          selectedRange: provider.range,
          onRangeChanged: context.read<DashboardAnalyticsProvider>().updateRange,
        ),
        const SizedBox(height: 16),
        OnboardingChecklistCard(snapshot: snapshot),
        const SizedBox(height: 16),
        if (currentCompany.company?.isDemoMode == true) ...[
          const DemoTourCard(),
          const SizedBox(height: 16),
        ],
        if (provider.error != null) ...[
          _DashboardErrorBanner(
            message: provider.error!,
            onRetry: currentCompany.refresh,
          ),
          const SizedBox(height: 16),
        ],
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: provider.isLoading && !provider.hasData
              ? const _DashboardAnalyticsSkeleton(
                  key: ValueKey('analytics-skeleton'),
                )
              : !provider.isLoading && !provider.hasData
                  ? _AnalyticsEmptyState(
                      key: const ValueKey('analytics-empty'),
                      onAction: () => context.go(AppRoutePaths.products),
                    )
                  : _AnalyticsContent(
                      key: const ValueKey('analytics-content'),
                      width: width,
                      snapshot: snapshot,
                      alertsProvider: alertsProvider,
                      requestsProvider: requestsProvider,
                    ),
        ),
      ],
    );
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

class _AnalyticsHero extends StatelessWidget {
  const _AnalyticsHero({
    required this.greeting,
    required this.snapshot,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  final String greeting;
  final DashboardAnalyticsSnapshot snapshot;
  final AnalyticsTimeRange selectedRange;
  final ValueChanged<AnalyticsTimeRange> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 980;
    return SectionCard(
      borderRadius: 30,
      gradient: LinearGradient(
        colors: [
          AppTheme.brand.withValues(alpha: 0.18),
          AppTheme.brandViolet.withValues(alpha: 0.12),
          theme.colorScheme.surface.withValues(alpha: 0.96),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroText(greeting: greeting, snapshot: snapshot),
                const SizedBox(height: 18),
                AnalyticsFilterBar(
                  selectedRange: selectedRange,
                  onRangeChanged: onRangeChanged,
                ),
                const SizedBox(height: 18),
                _HeroMeta(snapshot: snapshot),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: _HeroText(greeting: greeting, snapshot: snapshot),
                ),
                const SizedBox(width: 18),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnalyticsFilterBar(
                        selectedRange: selectedRange,
                        onRangeChanged: onRangeChanged,
                      ),
                      const SizedBox(height: 18),
                      _HeroMeta(snapshot: snapshot),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _HeroText extends StatelessWidget {
  const _HeroText({
    required this.greeting,
    required this.snapshot,
  });

  final String greeting;
  final DashboardAnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final delta = snapshot.movementDeltaPercent;
    final deltaLabel = delta >= 0
        ? '+${delta.toStringAsFixed(0)}% actividad'
        : '${delta.toStringAsFixed(0)}% actividad';
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
            'Hola, $greeting',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Un centro de analytics listo para decisiones de inventario en tiempo real.',
          style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: -0.9),
        ),
        const SizedBox(height: 10),
        Text(
          'Sigue entradas, salidas, riesgo operativo, severidad de alertas y colaboración desde una vista tipo SaaS enterprise.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.76),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _HeroBadge(
              icon: Icons.sync_alt_rounded,
              label: '${snapshot.movementsInRange} movimientos',
            ),
            _HeroBadge(
              icon: Icons.trending_up_rounded,
              label: deltaLabel,
            ),
            _HeroBadge(
              icon: Icons.health_and_safety_outlined,
              label: '${snapshot.stockCoverageScore.toStringAsFixed(0)}% health score',
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroMeta extends StatelessWidget {
  const _HeroMeta({required this.snapshot});

  final DashboardAnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      ('Stock total', snapshot.totalStock.toString()),
      ('Usuarios activos', snapshot.activeUsers.toString()),
      ('Pendientes', snapshot.pendingRequests.toString()),
    ];
    return Column(
      children: metrics
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _HeroMetric(label: item.$1, value: item.$2),
            ),
          )
          .toList(),
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
          Expanded(child: Text(label, style: theme.textTheme.titleMedium)),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: -0.8),
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({
    required this.width,
    required this.snapshot,
    required this.alertsProvider,
    required this.requestsProvider,
    super.key,
  });

  final double width;
  final DashboardAnalyticsSnapshot snapshot;
  final AlertsProvider alertsProvider;
  final StockRequestsProvider requestsProvider;

  @override
  Widget build(BuildContext context) {
    final columns = width < 780 ? 1 : width < 1180 ? 2 : 3;
    final kpis = [
      AnalyticsKpiCard(
        label: 'Stock total',
        value: snapshot.totalStock,
        helper: 'Unidades disponibles en todo el workspace',
        icon: Icons.inventory_2_outlined,
        accent: AppTheme.brand,
        trendLabel: '${snapshot.totalProducts} productos',
      ),
      AnalyticsKpiCard(
        label: 'Productos críticos',
        value: snapshot.criticalProducts,
        helper: 'Stock agotado o en punto crítico',
        icon: Icons.warning_amber_rounded,
        accent: AppTheme.warning,
        trendLabel: '${snapshot.expiredProducts} vencidos',
      ),
      AnalyticsKpiCard(
        label: 'Movimientos hoy',
        value: snapshot.movementsToday,
        helper: 'Actividad registrada en la jornada actual',
        icon: Icons.sync_alt_rounded,
        accent: AppTheme.success,
        trendLabel: '${snapshot.movementsWeek} semana',
      ),
      AnalyticsKpiCard(
        label: 'Entradas vs salidas',
        value: snapshot.entryExitBalance,
        helper: 'Balance neto del rango seleccionado',
        icon: Icons.compare_arrows_rounded,
        accent: AppTheme.brandViolet,
        trendLabel: '${snapshot.entriesInRange}/${snapshot.exitsInRange}',
      ),
      AnalyticsKpiCard(
        label: 'Crecimiento inventario',
        value: snapshot.inventoryGrowthPercent,
        helper: 'Variación estimada contra el stock de apertura',
        icon: Icons.trending_up_rounded,
        accent: const Color(0xFF38BDF8),
        trendLabel: '${snapshot.range.label} ',
      ),
      AnalyticsKpiCard(
        label: 'Ubicaciones activas',
        value: snapshot.activeLocations,
        helper: 'Espacios operativos registrados',
        icon: Icons.location_on_outlined,
        accent: const Color(0xFFF97316),
      ),
      AnalyticsKpiCard(
        label: 'Usuarios activos',
        value: snapshot.activeUsers,
        helper: 'Miembros activos dentro del workspace',
        icon: Icons.groups_2_outlined,
        accent: const Color(0xFF14B8A6),
      ),
      AnalyticsKpiCard(
        label: 'Requests pendientes',
        value: snapshot.pendingRequests,
        helper: 'Reposiciones esperando gestión',
        icon: Icons.assignment_late_outlined,
        accent: const Color(0xFFFB7185),
      ),
      AnalyticsKpiCard(
        label: 'Alertas activas',
        value: snapshot.activeAlerts,
        helper: 'Señales operativas abiertas en el workspace',
        icon: Icons.notification_important_outlined,
        accent: AppTheme.brandViolet,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: width < 780 ? 1.24 : 1.18,
          children: kpis,
        ).animate().fadeIn(duration: 320.ms),
        const SizedBox(height: 16),
        _SectionTitle(
          title: 'Tendencias',
          subtitle: 'Comportamiento del inventario en el rango temporal seleccionado.',
        ),
        const SizedBox(height: 12),
        if (width < 1100) ...[
          AnalyticsLineChartCard(
            title: 'Movimientos por día',
            subtitle: 'Volumen agregado de unidades movidas.',
            points: snapshot.movementsByDay,
          ),
          const SizedBox(height: 16),
          AnalyticsBarChartCard(
            title: 'Entradas vs salidas',
            subtitle: 'Comparativa directa entre abastecimiento y consumo.',
            points: snapshot.entriesVsExitsByDay,
          ),
          const SizedBox(height: 16),
          AnalyticsLineChartCard(
            title: 'Tendencia semanal',
            subtitle: 'Balance neto por semana para detectar aceleración o caída.',
            points: snapshot.weeklyTrend,
            accent: AppTheme.brandViolet,
          ),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: AnalyticsLineChartCard(
                  title: 'Movimientos por día',
                  subtitle: 'Volumen agregado de unidades movidas.',
                  points: snapshot.movementsByDay,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 5,
                child: AnalyticsBarChartCard(
                  title: 'Entradas vs salidas',
                  subtitle: 'Comparativa directa del flujo operativo.',
                  points: snapshot.entriesVsExitsByDay,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnalyticsLineChartCard(
            title: 'Tendencia semanal',
            subtitle: 'Balance neto por semana para detectar aceleración o caída.',
            points: snapshot.weeklyTrend,
            accent: AppTheme.brandViolet,
          ),
        ],
        const SizedBox(height: 16),
        _SectionTitle(
          title: 'Breakdowns',
          subtitle: 'Las distribuciones ayudan a leer dónde está el peso del negocio.',
        ),
        const SizedBox(height: 12),
        if (width < 1100) ...[
          AnalyticsRankedListCard(
            title: 'Productos más movidos',
            subtitle: 'SKU con mayor rotación en el rango seleccionado.',
            items: snapshot.topMovedProducts,
          ),
          const SizedBox(height: 16),
          AnalyticsDonutChartCard(
            title: 'Stock por categoría',
            subtitle: 'Distribución de unidades por categoría de producto.',
            items: snapshot.stockByCategory,
          ),
          const SizedBox(height: 16),
          AnalyticsDonutChartCard(
            title: 'Alertas por severidad',
            subtitle: 'Presión operativa de riesgo crítico, medio e informativo.',
            items: snapshot.alertsBySeverity,
          ),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: AnalyticsRankedListCard(
                  title: 'Productos más movidos',
                  subtitle: 'SKU con mayor rotación en el rango seleccionado.',
                  items: snapshot.topMovedProducts,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: AnalyticsDonutChartCard(
                  title: 'Stock por categoría',
                  subtitle: 'Distribución de unidades por categoría de producto.',
                  items: snapshot.stockByCategory,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: AnalyticsDonutChartCard(
                  title: 'Alertas por severidad',
                  subtitle: 'Riesgo operativo activo del workspace.',
                  items: snapshot.alertsBySeverity,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        if (width < 1100) ...[
          ActivityFeedCard(items: snapshot.activityItems),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: ActivityFeedCard(items: snapshot.activityItems),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 5,
                child: LowStockList(
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
              ),
            ],
          ),
      ],
    );
  }
}

class _AnalyticsEmptyState extends StatelessWidget {
  const _AnalyticsEmptyState({
    required this.onAction,
    super.key,
  });

  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: SizedBox(
        height: 360,
        child: Column(
          children: [
            const Expanded(
              child: EmptyState(
                title: 'Todavía no hay suficiente señal para analytics',
                subtitle:
                    'Agrega productos, registra movimientos y activa alertas para convertir este panel en un centro de decisiones.',
                icon: Icons.insights_rounded,
                compact: true,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add_box_outlined),
                  label: const Text('Agregar productos'),
                ),
                const _MockInsightChip(label: 'KPIs en tiempo real'),
                const _MockInsightChip(label: 'Comparativas por rango'),
                const _MockInsightChip(label: 'Activity insights'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MockInsightChip extends StatelessWidget {
  const _MockInsightChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: theme.textTheme.labelLarge),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.headlineSmall),
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

class _DashboardAnalyticsSkeleton extends StatelessWidget {
  const _DashboardAnalyticsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SkeletonBlock(height: 320, radius: 30),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: width < 780 ? 1 : width < 1180 ? 2 : 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.18,
          children: List.generate(
            width < 780 ? 3 : 6,
            (_) => const _SkeletonBlock(height: 160, radius: 28),
          ),
        ),
        const SizedBox(height: 16),
        const _SkeletonBlock(height: 280, radius: 28),
        const SizedBox(height: 16),
        const _SkeletonBlock(height: 280, radius: 28),
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

class _DashboardCompanyState extends StatelessWidget {
  const _DashboardCompanyState({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primaryLabel,
    required this.onPrimaryAction,
    this.secondaryLabel,
    this.onSecondaryAction,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String primaryLabel;
  final VoidCallback onPrimaryAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: SizedBox(
        height: 360,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: EmptyState(
                title: title,
                subtitle: subtitle,
                icon: icon,
                actionLabel: primaryLabel,
                onAction: onPrimaryAction,
                compact: true,
              ),
            ),
            if (secondaryLabel != null && onSecondaryAction != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: OutlinedButton.icon(
                  onPressed: onSecondaryAction,
                  icon: const Icon(Icons.add_business_outlined),
                  label: Text(secondaryLabel!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DashboardErrorBanner extends StatelessWidget {
  const _DashboardErrorBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Theme.of(context).colorScheme.error,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Text(message),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
