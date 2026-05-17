import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/app/routes.dart';
import 'package:stockmind/core/services/report_export_service.dart';
import 'package:stockmind/core/widgets/empty_state.dart';
import 'package:stockmind/core/widgets/export_feedback.dart';
import 'package:stockmind/core/widgets/section_card.dart';
import 'package:stockmind/core/widgets/stockmind_loading_screen.dart';
import 'package:stockmind/features/alerts/presentation/widgets/low_stock_list.dart';
import 'package:stockmind/features/alerts/providers/alerts_provider.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
import 'package:stockmind/features/company/providers/company_profile_provider.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/dashboard_frame.dart';
import 'package:stockmind/features/replenishment/presentation/widgets/stock_request_dialog.dart';
import 'package:stockmind/features/replenishment/providers/stock_requests_provider.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlertsProvider>();
    final auth = context.watch<AuthProvider>();
    final requestsProvider = context.watch<StockRequestsProvider>();
    final width = MediaQuery.sizeOf(context).width;
    final isSmallPhone = width < 480;
    final isMobile = width < 760;
    final crossAxisCount = isMobile ? 1 : width < 1180 ? 2 : 4;
    final metrics = [
      _AlertMetric(
        title: 'Activas',
        value: provider.activeAlertsCount.toString(),
        helper: 'Alertas que requieren acción',
        icon: Icons.notifications_active_outlined,
      ),
      _AlertMetric(
        title: 'Stock bajo',
        value: provider.lowStockAlertsCount.toString(),
        helper: 'Productos con 5 unidades o menos',
        icon: Icons.inventory_2_outlined,
      ),
      _AlertMetric(
        title: 'Por vencer',
        value: provider.expiringSoonAlertsCount.toString(),
        helper: 'Vencen dentro de 7 días',
        icon: Icons.event_available_outlined,
      ),
      _AlertMetric(
        title: 'Vencidos / resueltas',
        value:
            '${provider.expiredAlertsCount} / ${provider.resolvedAlertsCount}',
        helper: '${provider.unreadAlertsCount} sin leer',
        icon: Icons.task_alt_rounded,
      ),
    ];

    return DashboardFrame(
      title: 'Alertas',
      onBackPressed: () => context.go(AppRoutePaths.dashboard),
      backLabel: 'Volver',
      actions: [
        FilledButton.tonalIcon(
          onPressed: auth.canExport
              ? () => _exportAlerts(context, provider, auth)
              : null,
          icon: const Icon(Icons.download_rounded),
          label: const Text('Exportar'),
        ),
      ],
      subtitle:
          'Supervisa incidencias de stock y vencimiento en tiempo real, con resolución auditada y filtros operativos.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (provider.error != null) ...[
            _AlertsErrorBanner(message: provider.error!),
            SizedBox(height: isSmallPhone ? 12 : 16),
          ],
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final metric in metrics) ...[
                  metric,
                  SizedBox(height: isSmallPhone ? 12 : 14),
                ],
              ],
            )
          else
            GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.45,
              children: metrics,
            ),
          SizedBox(height: isSmallPhone ? 12 : 16),
          SectionCard(
            child: Padding(
              padding: EdgeInsets.all(isSmallPhone ? 16 : 18),
              child: Wrap(
                spacing: isSmallPhone ? 8 : 10,
                runSpacing: isSmallPhone ? 8 : 10,
                children: AlertsFilter.values
                    .map(
                      (filter) => ChoiceChip(
                        label: Text(_filterLabel(filter)),
                        selected: provider.filter == filter,
                        onSelected: (_) => provider.updateFilter(filter),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          SizedBox(height: isSmallPhone ? 12 : 16),
          if (provider.isLoading && !provider.hasAlerts)
            const SectionCard(
              child: SizedBox(
                height: 320,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: StockMindLoadingPanel(
                      compact: true,
                      statusMessage: 'Analizando alertas...',
                    ),
                  ),
                ),
              ),
            )
          else if (!provider.isLoading && provider.visibleAlerts.isEmpty)
            SectionCard(
              child: SizedBox(
                height: 320,
                child: EmptyState(
                  title: provider.filter == AlertsFilter.resolved
                      ? 'No hay alertas resueltas'
                      : 'Sin alertas para este filtro',
                  subtitle: provider.filter == AlertsFilter.resolved
                      ? 'Cuando resuelvas incidencias, quedarán registradas aquí.'
                      : 'Tus productos están en un nivel saludable o aún no requieren seguimiento.',
                  icon: Icons.notifications_none_rounded,
                  compact: true,
                ),
              ),
            )
          else
            LowStockList(
              alerts: provider.visibleAlerts,
              onMarkAsRead: (alert) => provider.markAsRead(alert.id),
              onResolve: (alert) => provider.resolveAlert(alert.id),
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
        ],
      ),
    );
  }

  String _filterLabel(AlertsFilter filter) {
    return switch (filter) {
      AlertsFilter.all => 'Todas',
      AlertsFilter.lowStock => 'Stock bajo',
      AlertsFilter.expiringSoon => 'Por vencer',
      AlertsFilter.expired => 'Vencidos',
      AlertsFilter.active => 'Activas',
      AlertsFilter.resolved => 'Resueltas',
    };
  }

  Future<void> _exportAlerts(
    BuildContext context,
    AlertsProvider provider,
    AuthProvider auth,
  ) async {
    final company = context.read<CompanyProfileProvider>().profile;
    await runExportTask(
      context: context,
      hasData: provider.visibleAlerts.isNotEmpty,
      noDataTitle: 'No hay alertas para exportar',
      noDataMessage:
          'Ajusta los filtros o espera nuevas incidencias antes de exportar.',
      successMessage: 'Las alertas fueron descargadas correctamente.',
      task: () => ReportExportService().exportAlertsCsv(
        alerts: provider.visibleAlerts,
        userName: auth.user?.displayName ?? auth.user?.email,
        companyProfile: company,
      ),
    );
  }
}

class _AlertMetric extends StatelessWidget {
  const _AlertMetric({
    required this.title,
    required this.value,
    required this.helper,
    required this.icon,
  });

  final String title;
  final String value;
  final String helper;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final isSmallPhone = width < 480;
    final isMobile = width < 760;
    return SectionCard(
      interactive: true,
      padding: EdgeInsets.all(isSmallPhone ? 16 : isMobile ? 16 : 20),
      borderRadius: isMobile ? 24 : 22,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: isSmallPhone ? 120 : isMobile ? 148 : 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: isSmallPhone ? 42 : 46,
                  height: isSmallPhone ? 42 : 46,
                  padding: EdgeInsets.all(isSmallPhone ? 8 : isMobile ? 9 : 10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: colorScheme.primary,
                    size: isSmallPhone ? 22 : isMobile ? 20 : 24,
                  ),
                ),
                const Spacer(),
                Text(
                  value,
                  style: (isMobile
                          ? theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            )
                          : theme.textTheme.headlineMedium)
                      ?.copyWith(fontSize: isSmallPhone ? 30 : null),
                ),
              ],
            ),
            SizedBox(height: isSmallPhone ? 10 : isMobile ? 12 : 16),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: isSmallPhone ? 17 : null,
              ),
            ),
            SizedBox(height: isSmallPhone ? 4 : isMobile ? 6 : 8),
            Text(
              helper,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: (isMobile ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)
                  ?.copyWith(fontSize: isSmallPhone ? 13 : null),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertsErrorBanner extends StatelessWidget {
  const _AlertsErrorBanner({required this.message});

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
