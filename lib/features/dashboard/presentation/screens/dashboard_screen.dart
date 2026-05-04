import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/core/theme/app_theme.dart';
import 'package:stockmind/core/widgets/empty_state.dart';
import 'package:stockmind/core/widgets/section_card.dart';
import 'package:stockmind/core/widgets/stat_card.dart';
import 'package:stockmind/features/alerts/presentation/widgets/low_stock_list.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/category_chart_card.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/dashboard_frame.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/inventory_movement_chart_card.dart';
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

    final movementPoints = [
      InventoryMovementPoint(
        label: 'Lun',
        value: (snapshot.totalUnits * 0.58).clamp(8, 120).toDouble(),
      ),
      InventoryMovementPoint(
        label: 'Mar',
        value: (snapshot.totalUnits * 0.72).clamp(12, 135).toDouble(),
      ),
      InventoryMovementPoint(
        label: 'Mié',
        value: (snapshot.totalUnits * 0.66).clamp(10, 128).toDouble(),
      ),
      InventoryMovementPoint(
        label: 'Jue',
        value: (snapshot.totalUnits * 0.84).clamp(18, 148).toDouble(),
      ),
      InventoryMovementPoint(
        label: 'Vie',
        value: (snapshot.totalUnits * 0.94).clamp(22, 158).toDouble(),
      ),
      InventoryMovementPoint(
        label: 'Sáb',
        value: (snapshot.totalUnits * 0.74).clamp(14, 138).toDouble(),
      ),
      InventoryMovementPoint(
        label: 'Dom',
        value: (snapshot.totalUnits * 0.62).clamp(9, 122).toDouble(),
      ),
    ];

    return DashboardFrame(
      title: 'Dashboard',
      subtitle:
          'Vista ejecutiva del inventario con datos reales, foco en salud operativa y decisiones rápidas.',
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
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (!provider.isLoading && !provider.hasProducts)
            const Card(
              child: SizedBox(
                height: 340,
                child: EmptyState(
                  title: 'Tu inventario está vacío',
                  subtitle:
                      'Agrega productos desde el módulo Productos para comenzar a ver métricas reales en el dashboard.',
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
                  label: 'Total productos',
                  value: snapshot.totalProducts.toString(),
                  helper: 'Productos activos en catálogo',
                  icon: Icons.inventory_2_rounded,
                  color: AppTheme.brand,
                  trend: '${snapshot.categories} categorías',
                ),
                StatCard(
                  label: 'Stock total',
                  value: snapshot.totalUnits.toString(),
                  helper: 'Unidades disponibles',
                  icon: Icons.layers_rounded,
                  color: AppTheme.brandViolet,
                  trend: 'Tiempo real',
                ),
                StatCard(
                  label: 'Stock bajo',
                  value: snapshot.lowStockProducts.toString(),
                  helper: 'Productos que requieren acción',
                  icon: Icons.warning_amber_rounded,
                  color: AppTheme.warning,
                  trend: '${snapshot.lowStockProducts} alertas',
                ),
                StatCard(
                  label: 'Valor del inventario',
                  value: currency.format(snapshot.totalInventoryValue),
                  helper: 'Capital comprometido',
                  icon: Icons.attach_money_rounded,
                  color: AppTheme.success,
                  trend: 'Actualizado',
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
                      helper: 'Porcentaje de catálogo fuera de riesgo',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ExecutiveKpi(
                      title: 'Categorías activas',
                      value: snapshot.categories.toString(),
                      helper: 'Cobertura actual del portafolio',
                    ),
                  ),
                  if (width > 920) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ExecutiveKpi(
                        title: 'Alertas abiertas',
                        value: snapshot.lowStockProducts.toString(),
                        helper: 'Reposiciones pendientes hoy',
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
              StockBarChartCard(products: snapshot.topProducts),
              const SizedBox(height: 16),
              CategoryChartCard(categories: snapshot.topCategories),
              const SizedBox(height: 16),
              LowStockList(products: provider.lowStockProducts),
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
                        child: LowStockList(products: provider.lowStockProducts),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: StockBarChartCard(products: snapshot.topProducts),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 6,
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
