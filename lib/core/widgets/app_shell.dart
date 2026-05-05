import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/core/theme/app_theme.dart';
import 'package:stockmind/core/widgets/app_alert_dialog.dart';
import 'package:stockmind/core/widgets/section_card.dart';
import 'package:stockmind/core/widgets/sidebar_item.dart';
import 'package:stockmind/core/widgets/stockmind_brand.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';

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
      _ShellDestination(label: 'Dashboard', icon: Icons.dashboard_rounded),
      _ShellDestination(label: 'Productos', icon: Icons.inventory_2_outlined),
      _ShellDestination(label: 'Alertas', icon: Icons.warning_amber_rounded),
      _ShellDestination(label: 'Ubicaciones', icon: Icons.location_on_outlined),
      _ShellDestination(label: 'Configuración', icon: Icons.settings_outlined),
    ];

    final sidebar = Container(
      width: 308,
      margin: const EdgeInsets.all(18),
      child: Column(
        children: [
          SectionCard(
            padding: EdgeInsets.zero,
            gradient: LinearGradient(
              colors: [
                theme.brightness == Brightness.dark
                    ? const Color(0xFF0E1830)
                    : Colors.white,
                theme.brightness == Brightness.dark
                    ? const Color(0xFF111C35)
                    : const Color(0xFFF5F8FF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _BrandBlock(),
                  const SizedBox(height: 24),
                  for (var index = 0; index < destinations.length; index++) ...[
                    SidebarItem(
                      label: destinations[index].label,
                      icon: destinations[index].icon,
                      selected: navigationShell.currentIndex == index,
                      onTap: () => navigationShell.goBranch(index),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 18),
                  const Divider(),
                  const SizedBox(height: 18),
                  SidebarItem(
                    label: 'Cerrar sesión',
                    icon: Icons.logout_rounded,
                    selected: false,
                    isDestructive: true,
                    onTap: () => _handleSidebarSignOut(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.brand.withValues(alpha: 0.12),
                  foregroundImage:
                      user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
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
                      const SizedBox(height: 2),
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
      drawer: isCompact ? Drawer(child: SafeArea(child: sidebar)) : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.scaffoldBackgroundColor,
              theme.brightness == Brightness.dark
                  ? const Color(0xFF050C17)
                  : const Color(0xFFF1F4FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (!isCompact) sidebar,
              Expanded(
                child: Padding(
                  padding: isCompact
                      ? EdgeInsets.zero
                      : const EdgeInsets.fromLTRB(0, 18, 18, 18),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isCompact ? 0 : 32),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.brightness == Brightness.dark
                                ? const Color(0xFF0A1324)
                                : Colors.white,
                            theme.brightness == Brightness.dark
                                ? const Color(0xFF0C162A)
                                : const Color(0xFFF8FBFF),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
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
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item.icon),
                      label: item.label,
                    ),
                  )
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
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.brand,
            AppTheme.brandViolet,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          const StockMindIconMark(
            size: 44,
            framed: true,
            framePadding: 12,
            frameRadius: 18,
            assetScale: 1.92,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'StockMind',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Inventory SaaS',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
        ],
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

Future<void> _handleSidebarSignOut(BuildContext context) async {
  final confirmed = await showAppConfirmDialog(
    context,
    title: '¿Seguro que quieres cerrar sesión?',
    message: 'Tu sesión actual se cerrará en este dispositivo.',
    confirmLabel: 'Cerrar sesión',
    cancelLabel: 'Cancelar',
  );
  if (!confirmed || !context.mounted) return;

  final auth = context.read<AuthProvider>();
  await auth.signOut();
  if (!context.mounted || auth.error == null) return;
  await showAppAlertDialog(
    context,
    type: AppAlertType.error,
    title: 'No se pudo cerrar sesión',
    message: auth.error!,
  );
}
