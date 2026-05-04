import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/features/alerts/presentation/widgets/low_stock_list.dart';
import 'package:stockmind/features/alerts/providers/alerts_provider.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/dashboard_frame.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlertsProvider>();

    return DashboardFrame(
      title: 'Alertas',
      subtitle: 'Monitorea automáticamente productos críticos y reposición pendiente.',
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: _AlertMetric(
                      title: 'Alertas activas',
                      value: provider.activeAlerts.toString(),
                      helper: 'SKUs por debajo del stock mínimo',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _AlertMetric(
                      title: 'Cobertura actual',
                      value: '${provider.coveragePercentage}%',
                      helper: 'Productos dentro de nivel saludable',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          LowStockList(products: provider.lowStockProducts),
        ],
      ),
    );
  }
}

class _AlertMetric extends StatelessWidget {
  const _AlertMetric({
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
