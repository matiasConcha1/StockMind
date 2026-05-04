import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/controllers/inventory_controller.dart';
import 'package:stockmind/core/utils/responsive.dart';
import 'package:stockmind/widgets/dashboard/low_stock_alert_card.dart';
import 'package:stockmind/widgets/dashboard/metric_card.dart';
import 'package:stockmind/widgets/dashboard/movement_list_card.dart';
import 'package:stockmind/widgets/dashboard/stock_chart_card.dart';
import 'package:stockmind/widgets/layout/dashboard_header.dart';

class DashboardOverviewScreen extends StatelessWidget {
  const DashboardOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryController>();
    final metrics = inventory.metrics;

    return SafeArea(
      child: Builder(
        builder: (context) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardHeader(
                title: 'Dashboard',
                subtitle:
                    'Visión general del inventario y movimientos recientes.',
                onMenuPressed: () => Scaffold.of(context).openDrawer(),
              ),
              const SizedBox(height: 24),
              GridView.builder(
                itemCount: metrics.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: Responsive.isMobile(context) ? 1 : 3,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  mainAxisExtent: 188,
                ),
                itemBuilder: (context, index) =>
                    MetricCard(metric: metrics[index]),
              ),
              const SizedBox(height: 24),
              if (Responsive.isMobile(context)) ...[
                StockChartCard(data: inventory.stockChartData),
                const SizedBox(height: 24),
                MovementListCard(movements: inventory.recentMovements),
                const SizedBox(height: 24),
                LowStockAlertCard(products: inventory.lowStockProducts),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          StockChartCard(data: inventory.stockChartData),
                          const SizedBox(height: 24),
                          MovementListCard(
                              movements: inventory.recentMovements),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: LowStockAlertCard(
                          products: inventory.lowStockProducts),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
