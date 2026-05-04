import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stockmind/core/utils/responsive.dart';
import 'package:stockmind/widgets/layout/dashboard_sidebar.dart';

class DashboardShell extends StatelessWidget {
  const DashboardShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final sidebar = DashboardSidebar(
      currentIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) {
        navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        );
      },
    );

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            sidebar,
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      drawer: Drawer(child: sidebar),
      body: navigationShell,
    );
  }
}
