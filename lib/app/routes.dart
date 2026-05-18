import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stockmind/core/widgets/app_shell.dart';
import 'package:stockmind/core/widgets/stockmind_loading_screen.dart';
import 'package:stockmind/features/alerts/presentation/screens/alerts_screen.dart';
import 'package:stockmind/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:stockmind/features/auth/presentation/screens/login_screen.dart';
import 'package:stockmind/features/auth/presentation/screens/register_screen.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
import 'package:stockmind/features/company/providers/current_company_provider.dart';
import 'package:stockmind/features/company/presentation/screens/company_screen.dart';
import 'package:stockmind/features/company/presentation/screens/invite_acceptance_screen.dart';
import 'package:stockmind/features/company/presentation/screens/workspace_type_selection_screen.dart';
import 'package:stockmind/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:stockmind/features/dashboard/presentation/screens/settings_screen.dart';
import 'package:stockmind/features/dashboard/presentation/screens/stock_movements_screen.dart';
import 'package:stockmind/features/locations/presentation/screens/locations_screen.dart';
import 'package:stockmind/features/products/presentation/screens/products_screen.dart';
import 'package:stockmind/features/products/presentation/screens/scan_product_screen.dart';
import 'package:stockmind/features/replenishment/presentation/screens/replenishment_screen.dart';
import 'package:stockmind/features/users/presentation/screens/users_management_screen.dart';

final class AppRoutePaths {
  static const loading = '/loading';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const invite = '/invite';
  static const dashboard = '/dashboard';
  static const products = '/products';
  static const alerts = '/alerts';
  static const locations = '/locations';
  static const settings = '/settings';
  static const workspaceSetup = '/workspace-setup';
  static const company = '/company';
  static const companyLegacy = '/empresa';
  static const users = '/users';
  static const usersLegacy = '/usuarios';
  static const activity = '/activity';
  static const activityLegacy = '/historial';
  static const scan = '/scan';
  static const replenishment = '/replenishment';
  static const replenishmentLegacy = '/reposicion';
}

final class AppRouteNames {
  static const loading = 'loading';
  static const login = 'login';
  static const register = 'register';
  static const forgotPassword = 'forgot-password';
  static const invite = 'invite';
  static const dashboard = 'dashboard';
  static const products = 'products';
  static const alerts = 'alerts';
  static const locations = 'locations';
  static const settings = 'settings';
  static const workspaceSetup = 'workspace-setup';
  static const company = 'company';
  static const companyLegacy = 'empresa';
  static const users = 'users';
  static const usersLegacy = 'usuarios';
  static const activity = 'activity';
  static const activityLegacy = 'historial';
  static const scan = 'scan';
  static const replenishment = 'replenishment';
  static const replenishmentLegacy = 'reposicion';
}

class AppRoutes {
  const AppRoutes._();

  static GoRouter createRouter({
    required AuthProvider authProvider,
    required CurrentCompanyProvider currentCompanyProvider,
  }) {
    return GoRouter(
      initialLocation: AppRoutePaths.loading,
      refreshListenable: Listenable.merge([
        authProvider,
        currentCompanyProvider,
      ]),
      redirect: (context, state) {
        final currentLocation = state.matchedLocation;
        final isAuthRoute = <String>{
          AppRoutePaths.login,
          AppRoutePaths.register,
          AppRoutePaths.forgotPassword,
        }.contains(currentLocation);
        final isInviteRoute = currentLocation.startsWith('${AppRoutePaths.invite}/');

        debugPrint(
          'AppRoutes.redirect: location=$currentLocation '
          'loading=${authProvider.isLoading} '
          'initialized=${authProvider.initialized} '
          'authenticated=${authProvider.isAuthenticated}',
        );

        if (authProvider.isLoading) {
          if (currentLocation == AppRoutePaths.loading) return null;
          return AppRoutePaths.loading;
        }

        if (!authProvider.isAuthenticated) {
          if (currentLocation == AppRoutePaths.login ||
              currentLocation == AppRoutePaths.register ||
              currentLocation == AppRoutePaths.forgotPassword ||
              isInviteRoute) {
            return null;
          }
          return AppRoutePaths.login;
        }

        if (currentCompanyProvider.isLoading) {
          if (currentLocation == AppRoutePaths.loading || isInviteRoute) {
            return null;
          }
          return AppRoutePaths.loading;
        }

        if (currentCompanyProvider.needsWorkspaceSelection) {
          if (currentLocation == AppRoutePaths.workspaceSetup || isInviteRoute) {
            return null;
          }
          return AppRoutePaths.workspaceSetup;
        }

        if (authProvider.isAuthenticated &&
            (isAuthRoute || currentLocation == AppRoutePaths.loading)) {
          final redirectTarget = state.uri.queryParameters['redirect']?.trim();
          if (redirectTarget != null && redirectTarget.startsWith('/')) {
            return redirectTarget;
          }
          return AppRoutePaths.dashboard;
        }

        if (authProvider.isAuthenticated &&
            currentLocation == AppRoutePaths.workspaceSetup &&
            currentCompanyProvider.hasAcceptedMembership) {
          return AppRoutePaths.dashboard;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutePaths.workspaceSetup,
          name: AppRouteNames.workspaceSetup,
          pageBuilder: (context, state) =>
              _buildPage(state, const WorkspaceTypeSelectionScreen()),
        ),
        GoRoute(
          path: AppRoutePaths.loading,
          name: AppRouteNames.loading,
          pageBuilder: (context, state) =>
              _buildPage(state, const StockMindLoadingScreen()),
        ),
        GoRoute(
          path: AppRoutePaths.login,
          name: AppRouteNames.login,
          pageBuilder: (context, state) => _buildPage(state, const LoginScreen()),
        ),
        GoRoute(
          path: AppRoutePaths.register,
          name: AppRouteNames.register,
          pageBuilder: (context, state) =>
              _buildPage(state, const RegisterScreen()),
        ),
        GoRoute(
          path: AppRoutePaths.forgotPassword,
          name: AppRouteNames.forgotPassword,
          pageBuilder: (context, state) =>
              _buildPage(state, const ForgotPasswordScreen()),
        ),
        GoRoute(
          path: '${AppRoutePaths.invite}/:token',
          name: AppRouteNames.invite,
          pageBuilder: (context, state) => _buildPage(
            state,
            InviteAcceptanceScreen(
              inviteToken: state.pathParameters['token'] ?? '',
            ),
          ),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return AppShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutePaths.dashboard,
                  name: AppRouteNames.dashboard,
                  pageBuilder: (context, state) =>
                      _buildPage(state, const DashboardScreen()),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutePaths.products,
                  name: AppRouteNames.products,
                  pageBuilder: (context, state) =>
                      _buildPage(state, const ProductsScreen()),
                ),
                GoRoute(
                  path: AppRoutePaths.scan,
                  name: AppRouteNames.scan,
                  pageBuilder: (context, state) =>
                      _buildPage(state, const ScanProductScreen()),
                ),
                GoRoute(
                  path: AppRoutePaths.replenishment,
                  name: AppRouteNames.replenishment,
                  pageBuilder: (context, state) =>
                      _buildPage(state, const ReplenishmentScreen()),
                ),
                GoRoute(
                  path: AppRoutePaths.replenishmentLegacy,
                  name: AppRouteNames.replenishmentLegacy,
                  pageBuilder: (context, state) =>
                      _buildPage(state, const ReplenishmentScreen()),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutePaths.alerts,
                  name: AppRouteNames.alerts,
                  pageBuilder: (context, state) =>
                      _buildPage(state, const AlertsScreen()),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutePaths.locations,
                  name: AppRouteNames.locations,
                  pageBuilder: (context, state) =>
                      _buildPage(state, const LocationsScreen()),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutePaths.settings,
                  name: AppRouteNames.settings,
                  pageBuilder: (context, state) =>
                      _buildPage(state, const SettingsScreen()),
                ),
                GoRoute(
                  path: AppRoutePaths.company,
                  name: AppRouteNames.company,
                  pageBuilder: (context, state) =>
                      _buildPage(state, const CompanyScreen()),
                ),
                GoRoute(
                  path: AppRoutePaths.companyLegacy,
                  name: AppRouteNames.companyLegacy,
                  pageBuilder: (context, state) =>
                      _buildPage(state, const CompanyScreen()),
                ),
                GoRoute(
                  path: AppRoutePaths.users,
                  name: AppRouteNames.users,
                  pageBuilder: (context, state) =>
                      _buildPage(state, const UsersManagementScreen()),
                ),
                GoRoute(
                  path: AppRoutePaths.usersLegacy,
                  name: AppRouteNames.usersLegacy,
                  pageBuilder: (context, state) =>
                      _buildPage(state, const UsersManagementScreen()),
                ),
                GoRoute(
                  path: AppRoutePaths.activity,
                  name: AppRouteNames.activity,
                  pageBuilder: (context, state) =>
                      _buildPage(state, const StockMovementsScreen()),
                ),
                GoRoute(
                  path: AppRoutePaths.activityLegacy,
                  name: AppRouteNames.activityLegacy,
                  pageBuilder: (context, state) =>
                      _buildPage(state, const StockMovementsScreen()),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static CustomTransitionPage<void> _buildPage(
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0.02, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }
}
