import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/core/theme/app_theme.dart';
import 'package:stockmind/features/alerts/presentation/widgets/low_stock_list.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/category_chart_card.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/dashboard_frame.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/stock_bar_chart_card.dart';
import 'package:stockmind/features/dashboard/providers/dashboard_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final snapshot = provider.snapshot;
    final currency = NumberFormat.currency(symbol: '\$');
    final width = MediaQuery.sizeOf(context).width;
    final statCrossAxisCount = width < 720 ? 1 : width < 1180 ? 2 : 4;

    return DashboardFrame(
      title: 'Dashboard',
      subtitle: 'Control operativo del inventario, salud de stock y valor financiero.',
      actions: [
        OutlinedButton.icon(
          onPressed: provider.canSeedDemoData ? provider.seedDemoProducts : null,
          icon: const Icon(Icons.auto_awesome_rounded),
          label: const Text('Cargar demo'),
        ),
      ],
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: statCrossAxisCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.35,
            children: [
              StatCard(
                label: 'SKUs activos',
                value: snapshot.totalProducts.toString(),
                helper: 'Productos publicados',
                icon: Icons.inventory_2_rounded,
                color: AppTheme.brand,
              ),
              StatCard(
                label: 'Unidades totales',
                value: snapshot.totalUnits.toString(),
                helper: 'Disponibilidad consolidada',
                icon: Icons.widgets_rounded,
                color: const Color(0xFF0EA5E9),
              ),
              StatCard(
                label: 'Bajo stock',
                value: snapshot.lowStockProducts.toString(),
                helper: 'Requieren atención',
                icon: Icons.warning_amber_rounded,
                color: AppTheme.warning,
              ),
              StatCard(
                label: 'Valor inventario',
                value: currency.format(snapshot.totalInventoryValue),
                helper: 'Capital inmovilizado',
                icon: Icons.attach_money_rounded,
                color: AppTheme.success,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: _ScoreTile(
                      title: 'Stock health score',
                      value: '${snapshot.stockHealthScore.toStringAsFixed(0)}%',
                      helper: 'Porcentaje de SKUs fuera de riesgo',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ScoreTile(
                      title: 'Categorías activas',
                      value: snapshot.categories.toString(),
                      helper: 'Diversidad del catálogo actual',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (width < 1100) ...[
            StockBarChartCard(products: snapshot.topProducts),
            const SizedBox(height: 16),
            CategoryChartCard(categories: snapshot.topCategories),
            const SizedBox(height: 16),
            LowStockList(products: provider.lowStockProducts),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      StockBarChartCard(products: snapshot.topProducts),
                      const SizedBox(height: 16),
                      CategoryChartCard(categories: snapshot.topCategories),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: LowStockList(products: provider.lowStockProducts),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ScoreTile extends StatelessWidget {
  const _ScoreTile({
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
        borderRadius: BorderRadius.circular(24),
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
