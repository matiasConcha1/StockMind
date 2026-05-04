import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/app/app.dart';
import 'package:stockmind/core/theme/theme_provider.dart';
import 'package:stockmind/core/utils/firebase_bootstrap.dart';
import 'package:stockmind/features/alerts/providers/alerts_provider.dart';
import 'package:stockmind/features/auth/data/services/auth_service.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
import 'package:stockmind/features/dashboard/data/services/stock_service.dart';
import 'package:stockmind/features/dashboard/providers/dashboard_provider.dart';
import 'package:stockmind/features/products/data/services/product_service.dart';
import 'package:stockmind/features/products/providers/products_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bootstrap = await FirebaseBootstrap.initialize();
  final themeProvider = ThemeProvider();
  await themeProvider.load();

  final authProvider = AuthProvider(AuthService())..start();
  final productsProvider = ProductsProvider(
    authProvider: authProvider,
    productService: ProductService(),
  );
  final dashboardProvider = DashboardProvider(
    productsProvider: productsProvider,
    stockService: StockService(),
  );
  final alertsProvider = AlertsProvider(productsProvider: productsProvider);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(create: (_) => themeProvider),
        ChangeNotifierProvider<AuthProvider>(create: (_) => authProvider),
        ChangeNotifierProvider<ProductsProvider>(create: (_) => productsProvider),
        ChangeNotifierProvider<DashboardProvider>(create: (_) => dashboardProvider),
        ChangeNotifierProvider<AlertsProvider>(create: (_) => alertsProvider),
      ],
      child: StockMindApp(bootstrap: bootstrap),
    ),
  );
}
