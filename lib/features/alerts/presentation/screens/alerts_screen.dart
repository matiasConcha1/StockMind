import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/core/widgets/empty_state.dart';
import 'package:stockmind/core/widgets/stockmind_loading_screen.dart';
import 'package:stockmind/features/alerts/presentation/widgets/low_stock_list.dart';
import 'package:stockmind/features/alerts/providers/alerts_provider.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/dashboard_frame.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlertsProvider>();
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width < 760 ? 1 : width < 1180 ? 2 : 4;

    return DashboardFrame(
      title: 'Alertas',
      subtitle:
          'Supervisa incidencias de stock en tiempo real y resuelve riesgos antes de afectar tu operación.',
      child: Column(
        children: [
          if (provider.error != null) ...[
            _AlertsErrorBanner(message: provider.error!),
            const SizedBox(height: 16),
          ],
          GridView.count(
            crossAxisCount: crossAxisCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: width < 760 ? 2.3 : 1.45,
            children: [
              _AlertMetric(
                title: 'Activas',
                value: provider.activeAlertsCount.toString(),
                helper: 'Alertas que requieren acción',
                icon: Icons.notifications_active_outlined,
              ),
              _AlertMetric(
                title: 'Críticas',
                value: provider.criticalAlertsCount.toString(),
                helper: 'Productos sin stock disponible',
                icon: Icons.report_gmailerrorred_rounded,
              ),
              _AlertMetric(
                title: 'Altas / medias',
                value:
                    '${provider.highAlertsCount} / ${provider.mediumAlertsCount}',
                helper: 'Riesgo alto y preventivo',
                icon: Icons.stacked_line_chart_rounded,
              ),
              _AlertMetric(
                title: 'Resueltas',
                value: provider.resolvedAlertsCount.toString(),
                helper: '${provider.unreadAlertsCount} sin leer',
                icon: Icons.task_alt_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
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
          const SizedBox(height: 16),
          if (provider.isLoading && !provider.hasAlerts)
            const Card(
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
            Card(
              child: SizedBox(
                height: 320,
                child: EmptyState(
                  title: provider.filter == AlertsFilter.resolved
                      ? 'No hay alertas resueltas'
                      : 'Sin alertas activas',
                  subtitle: provider.filter == AlertsFilter.resolved
                      ? 'Cuando resuelvas incidencias, quedarán registradas aquí.'
                      : 'Tus productos están en un nivel saludable o aún no requieren seguimiento.',
                  icon: Icons.notifications_none_rounded,
                ),
              ),
            )
          else
            LowStockList(
              alerts: provider.visibleAlerts,
              onMarkAsRead: (alert) => provider.markAsRead(alert.id),
              onResolve: (alert) => provider.resolveAlert(alert.id),
            ),
        ],
      ),
    );
  }

  String _filterLabel(AlertsFilter filter) {
    return switch (filter) {
      AlertsFilter.all => 'Todas',
      AlertsFilter.critical => 'Críticas',
      AlertsFilter.high => 'Altas',
      AlertsFilter.medium => 'Medias',
      AlertsFilter.resolved => 'Resueltas',
    };
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: colorScheme.primary),
          ),
          const SizedBox(height: 14),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(value, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(helper, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _AlertsErrorBanner extends StatelessWidget {
  const _AlertsErrorBanner({required this.message});

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
