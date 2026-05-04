import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/controllers/auth_controller.dart';
import 'package:stockmind/core/utils/responsive.dart';
import 'package:stockmind/widgets/common/stockmind_logo.dart';

class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  static const destinations = [
    NavigationRailDestination(
      icon: Icon(Icons.dashboard_customize_outlined),
      selectedIcon: Icon(Icons.dashboard_customize_rounded),
      label: Text('Dashboard'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2_rounded),
      label: Text('Productos'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.notifications_none_rounded),
      selectedIcon: Icon(Icons.notifications_active_rounded),
      label: Text('Alertas'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings_rounded),
      label: Text('Ajustes'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = Responsive.isDesktop(context);

    return Container(
      width: isDesktop ? 280 : 86,
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        border: Border(
          right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.7)),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(isDesktop ? 24 : 16),
              child: StockMindLogo(showSubtitle: isDesktop),
            ),
            Expanded(
              child: NavigationRail(
                selectedIndex: currentIndex,
                onDestinationSelected: onDestinationSelected,
                extended: isDesktop,
                useIndicator: true,
                minExtendedWidth: 240,
                backgroundColor: Colors.transparent,
                destinations: destinations,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: () async {
                  await context.read<AuthController>().logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                icon: const Icon(Icons.logout_rounded),
                label: Text(isDesktop ? 'Cerrar sesión' : 'Salir'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
