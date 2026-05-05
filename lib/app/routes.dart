import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stockmind/core/widgets/app_shell.dart';
import 'package:stockmind/core/widgets/stockmind_loading_screen.dart';
import 'package:stockmind/features/alerts/presentation/screens/alerts_screen.dart';
import 'package:stockmind/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:stockmind/features/auth/presentation/screens/login_screen.dart';
import 'package:stockmind/features/auth/presentation/screens/register_screen.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
import 'package:stockmind/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:stockmind/features/dashboard/presentation/screens/settings_screen.dart';
import 'package:stockmind/features/locations/presentation/screens/locations_screen.dart';
import 'package:stockmind/features/products/presentation/screens/products_screen.dart';

final class AppRoutePaths {
  static const loading = '/loading';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const dashboard = '/dashboard';
  static const products = '/products';
  static const alerts = '/alerts';
  static const locations = '/locations';
  static const settings = '/settings';
}

final class AppRouteNames {
  static const loading = 'loading';
  static const login = 'login';
  static const register = 'register';
  static const forgotPassword = 'forgot-password';
  static const dashboard = 'dashboard';
  static const products = 'products';
  static const alerts = 'alerts';
  static const locations = 'locations';
  static const settings = 'settings';
}

class AppRoutes {
  const AppRoutes._();

  static GoRouter createRouter({required AuthProvider authProvider}) {
    return GoRouter(
      initialLocation: AppRoutePaths.loading,
      refreshListenable: authProvider,
      redirect: (context, state) {
        final currentLocation = state.matchedLocation;
        final isAuthRoute = <String>{
          AppRoutePaths.login,
          AppRoutePaths.register,
          AppRoutePaths.forgotPassword,
        }.contains(currentLocation);

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
              currentLocation == AppRoutePaths.forgotPassword) {
            return null;
          }
          return AppRoutePaths.login;
        }

        if (authProvider.isAuthenticated &&
            (isAuthRoute || currentLocation == AppRoutePaths.loading)) {
          return AppRoutePaths.dashboard;
        }

        return null;
      },
      routes: [
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
