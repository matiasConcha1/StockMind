import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/core/router/app_router.dart';
import 'package:stockmind/core/theme/app_theme.dart';
import 'package:stockmind/core/theme/theme_provider.dart';
import 'package:stockmind/features/app/presentation/firebase_setup_screen.dart';
import 'package:stockmind/providers/auth_provider.dart';
import 'package:stockmind/providers/products_provider.dart';
import 'package:stockmind/services/auth/auth_service.dart';
import 'package:stockmind/services/firebase_bootstrap.dart';
import 'package:stockmind/services/products/product_service.dart';
import 'package:stockmind/services/stock/stock_service.dart';

class StockMindApp extends StatefulWidget {
  const StockMindApp({
    required this.bootstrap,
    required this.themeProvider,
    super.key,
  });

  final FirebaseBootstrapResult bootstrap;
  final ThemeProvider themeProvider;

  @override
  State<StockMindApp> createState() => _StockMindAppState();
}

class _StockMindAppState extends State<StockMindApp> {
  AppRouter? _appRouter;
  AuthProvider? _authProvider;
  ProductsProvider? _productsProvider;

  @override
  void dispose() {
    _appRouter?.dispose();
    _productsProvider?.dispose();
    _authProvider?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.bootstrap.isReady) {
      return ChangeNotifierProvider<ThemeProvider>.value(
        value: widget.themeProvider,
        child: Consumer<ThemeProvider>(
          builder: (context, theme, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'StockMind',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: theme.themeMode,
              home: FirebaseSetupScreen(errorMessage: widget.bootstrap.error),
            );
          },
        ),
      );
    }

    _authProvider ??= AuthProvider(AuthService())..start();
    _productsProvider ??= ProductsProvider(
      authProvider: _authProvider!,
      productService: ProductService(),
      stockService: StockService(),
    );
    _appRouter ??= AppRouter(authProvider: _authProvider!);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: widget.themeProvider),
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider!),
        ChangeNotifierProvider<ProductsProvider>.value(value: _productsProvider!),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'StockMind',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: theme.themeMode,
            routerConfig: _appRouter!.router,
          );
        },
      ),
    );
  }
}
