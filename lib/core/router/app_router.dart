import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stockmind/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:stockmind/features/auth/presentation/screens/login_screen.dart';
import 'package:stockmind/features/auth/presentation/screens/register_screen.dart';
import 'package:stockmind/features/dashboard/presentation/screens/alerts_screen.dart';
import 'package:stockmind/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:stockmind/features/dashboard/presentation/screens/products_screen.dart';
import 'package:stockmind/features/dashboard/presentation/screens/settings_screen.dart';
import 'package:stockmind/features/shell/presentation/app_shell.dart';
import 'package:stockmind/providers/auth_provider.dart';

class AppRouter {
  AppRouter({required AuthProvider authProvider}) : _authProvider = authProvider;

  final AuthProvider _authProvider;

  late final GoRouter router = GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: _authProvider,
    redirect: (context, state) {
      if (!_authProvider.initialized) return null;

      final isAuthRoute = {
        '/login',
        '/register',
        '/forgot-password',
      }.contains(state.matchedLocation);

      if (!_authProvider.isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      if (_authProvider.isAuthenticated && isAuthRoute) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _page(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _page(state, const RegisterScreen()),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => _page(state, const ForgotPasswordScreen()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                pageBuilder: (context, state) => _page(state, const DashboardScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/products',
                pageBuilder: (context, state) => _page(state, const ProductsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/alerts',
                pageBuilder: (context, state) => _page(state, const AlertsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (context, state) => _page(state, const SettingsScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  CustomTransitionPage<void> _page(GoRouterState state, Widget child) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0.02, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }

  void dispose() {
    router.dispose();
  }
}
