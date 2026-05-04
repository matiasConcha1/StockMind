import 'package:go_router/go_router.dart';
import 'package:stockmind/controllers/auth_controller.dart';
import 'package:stockmind/screens/auth/login_screen.dart';
import 'package:stockmind/screens/auth/register_screen.dart';
import 'package:stockmind/screens/dashboard/alerts_screen.dart';
import 'package:stockmind/screens/dashboard/dashboard_overview_screen.dart';
import 'package:stockmind/screens/dashboard/dashboard_shell.dart';
import 'package:stockmind/screens/dashboard/products_screen.dart';
import 'package:stockmind/screens/dashboard/settings_screen.dart';

class AppRouter {
  AppRouter({required AuthController authController})
      : _authController = authController;

  final AuthController _authController;

  late final GoRouter router = GoRouter(
    initialLocation: '/login',
    refreshListenable: _authController,
    redirect: (context, state) {
      final isAuthenticated = _authController.isAuthenticated;
      final authLocation = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isAuthenticated && !authLocation) {
        return '/login';
      }

      if (isAuthenticated && authLocation) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return DashboardShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardOverviewScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/products',
                builder: (context, state) => const ProductsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/alerts',
                builder: (context, state) => const AlertsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  void dispose() {
    router.dispose();
  }
}
