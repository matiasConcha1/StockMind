import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/core/theme/app_theme.dart';
import 'package:stockmind/core/widgets/app_alert_dialog.dart';
import 'package:stockmind/core/widgets/section_card.dart';
import 'package:stockmind/core/widgets/sidebar_item.dart';
import 'package:stockmind/core/widgets/stockmind_brand.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
import 'package:stockmind/features/users/providers/user_provider.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;
    final authUser = context.watch<AuthProvider>().user;
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.currentUser ?? authUser;

    final destinations = [
      const _ShellDestination(
        branchIndex: 0,
        label: 'Centro de inventario',
        mobileLabel: 'Inicio',
        icon: Icons.space_dashboard_rounded,
      ),
      const _ShellDestination(
        branchIndex: 1,
        label: 'Productos',
        mobileLabel: 'Productos',
        icon: Icons.inventory_2_outlined,
      ),
      const _ShellDestination(
        branchIndex: 2,
        label: 'Alertas',
        mobileLabel: 'Alertas',
        icon: Icons.warning_amber_rounded,
      ),
      const _ShellDestination(
        branchIndex: 3,
        label: 'Ubicaciones',
        mobileLabel: 'Ubic.',
        icon: Icons.location_on_outlined,
      ),
      const _ShellDestination(
        branchIndex: 4,
        label: 'Configuración',
        mobileLabel: 'Ajustes',
        icon: Icons.settings_outlined,
      ),
    ];

    final sidebar = _DesktopSidebar(
      width: width < 1040 ? 278 : 308,
      destinations: destinations,
      navigationShell: navigationShell,
      user: user,
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.scaffoldBackgroundColor,
              theme.brightness == Brightness.dark
                  ? const Color(0xFF040B16)
                  : const Color(0xFFF2F6FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (!isMobile)
                sidebar
                    .animate()
                    .fadeIn(duration: 260.ms)
                    .slideX(begin: -0.02, end: 0),
              Expanded(
                child: Padding(
                  padding: isMobile
                      ? const EdgeInsets.fromLTRB(10, 8, 10, 0)
                      : const EdgeInsets.fromLTRB(0, 18, 18, 18),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isMobile ? 0 : 32),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
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
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.92),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: theme.brightness == Brightness.dark ? 0.22 : 0.08,
                            ),
                            blurRadius: 42,
                            spreadRadius: -22,
                            offset: const Offset(0, 24),
                          ),
                        ],
                      ),
                      child: navigationShell
                          .animate(target: navigationShell.currentIndex.toDouble())
                          .fadeIn(duration: 200.ms),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: isMobile
          ? SafeArea(
              top: false,
              child: NavigationBar(
                selectedIndex: _selectedNavIndex(
                  destinations,
                  navigationShell.currentIndex,
                ),
                onDestinationSelected: (index) =>
                    navigationShell.goBranch(destinations[index].branchIndex),
                height: 72,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: destinations
                    .map(
                      (item) => NavigationDestination(
                        icon: Icon(item.icon),
                        label: item.mobileLabel ?? item.label,
                      ),
                    )
                    .toList(),
              ),
            )
          : null,
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.width,
    required this.destinations,
    required this.navigationShell,
    required this.user,
  });

  final double width;
  final List<_ShellDestination> destinations;
  final StatefulNavigationShell navigationShell;
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: Container(
        margin: const EdgeInsets.all(18),
        child: Column(
          children: [
            SectionCard(
              padding: EdgeInsets.zero,
              borderRadius: 32,
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _BrandBlock(),
                    const SizedBox(height: 18),
                    for (final destination in destinations) ...[
                      SidebarItem(
                        label: destination.label,
                        icon: destination.icon,
                        selected:
                            navigationShell.currentIndex == destination.branchIndex,
                        onTap: () =>
                            navigationShell.goBranch(destination.branchIndex),
                      ),
                      const SizedBox(height: 6),
                    ],
                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 14),
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
              borderRadius: 28,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.brand.withValues(alpha: 0.12),
                    foregroundImage:
                        user?.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                    child: Text(
                      _buildUserInitial(user?.displayName),
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
      ),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.brand,
            AppTheme.brandViolet,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brand.withValues(alpha: 0.22),
            blurRadius: 30,
            spreadRadius: -18,
            offset: const Offset(0, 18),
          ),
        ],
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
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'StockMind',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Smart inventory platform',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
    required this.branchIndex,
    required this.label,
    required this.icon,
    this.mobileLabel,
  });

  final int branchIndex;
  final String label;
  final IconData icon;
  final String? mobileLabel;
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
  if (context.mounted) {
    context.read<UserProvider>().clear();
  }
  if (!context.mounted || auth.error == null) return;
  await showAppAlertDialog(
    context,
    type: AppAlertType.error,
    title: 'No se pudo cerrar sesión',
    message: auth.error!,
  );
}

int _selectedNavIndex(
  List<_ShellDestination> destinations,
  int branchIndex,
) {
  final visibleIndex = destinations.indexWhere(
    (destination) => destination.branchIndex == branchIndex,
  );
  return visibleIndex == -1 ? 0 : visibleIndex;
}

String _buildUserInitial(String? value) {
  final clean = value?.trim() ?? '';
  if (clean.isEmpty) {
    return 'S';
  }
  return clean.substring(0, 1).toUpperCase();
}
