import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/core/theme/app_theme.dart';
import 'package:stockmind/providers/auth_provider.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = MediaQuery.sizeOf(context).width < 1000;
    final user = context.watch<AuthProvider>().user;

    final destinations = const [
      _ShellDestination(label: 'Dashboard', icon: Icons.space_dashboard_rounded),
      _ShellDestination(label: 'Productos', icon: Icons.inventory_2_rounded),
      _ShellDestination(label: 'Alertas', icon: Icons.warning_amber_rounded),
      _ShellDestination(label: 'Ajustes', icon: Icons.tune_rounded),
    ];

    final rail = Container(
      width: 290,
      margin: const EdgeInsets.all(18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BrandBlock(),
          const SizedBox(height: 26),
          for (var index = 0; index < destinations.length; index++) ...[
            _SidebarTile(
              destination: destinations[index],
              selected: navigationShell.currentIndex == index,
              onTap: () => navigationShell.goBranch(index),
            ),
            const SizedBox(height: 8),
          ],
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? const Color(0xFF101A2D)
                  : const Color(0xFFF7FAFF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.brand.withValues(alpha: 0.12),
                  foregroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                  child: Text(
                    (user?.displayName.isNotEmpty ?? false)
                        ? user!.displayName.characters.first.toUpperCase()
                        : 'S',
                    style: const TextStyle(color: AppTheme.brand),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'Sin sesión',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        user?.email ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      drawer: isCompact ? Drawer(child: SafeArea(child: rail)) : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.scaffoldBackgroundColor,
              theme.brightness == Brightness.dark
                  ? const Color(0xFF050C17)
                  : const Color(0xFFEFF4FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (!isCompact) rail,
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(0, 18, 18, isCompact ? 88 : 18),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: ColoredBox(
                      color: theme.brightness == Brightness.dark
                          ? const Color(0xFF08111F)
                          : const Color(0xFFF8FBFF),
                      child: navigationShell,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: isCompact
          ? NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => navigationShell.goBranch(index),
              destinations: destinations
                  .map((item) => NavigationDestination(
                        icon: Icon(item.icon),
                        label: item.label,
                      ))
                  .toList(),
            )
          : null,
    );
  }
}

class _BrandBlock extends StatelessWidget {
  const _BrandBlock();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.brand,
            theme.brightness == Brightness.dark ? const Color(0xFF123171) : const Color(0xFF0F172A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.insights_rounded, color: Colors.white),
          ),
          const SizedBox(height: 22),
          Text(
            'StockMind',
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Controla inventario, alertas y valor de stock en una sola vista.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _ShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? AppTheme.brand.withValues(alpha: 0.12) : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                destination.icon,
                color: selected ? AppTheme.brand : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Text(
                destination.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: selected ? AppTheme.brand : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}
