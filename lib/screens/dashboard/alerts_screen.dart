import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/controllers/inventory_controller.dart';
import 'package:stockmind/widgets/dashboard/low_stock_alert_card.dart';
import 'package:stockmind/widgets/layout/dashboard_header.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryController>();

    return SafeArea(
      child: Builder(
        builder: (context) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              DashboardHeader(
                title: 'Alertas',
                subtitle:
                    'Productos que requieren atención inmediata por bajo stock.',
                onMenuPressed: () => Scaffold.of(context).openDrawer(),
              ),
              const SizedBox(height: 24),
              LowStockAlertCard(products: inventory.lowStockProducts),
            ],
          ),
        ),
      ),
    );
  }
}
