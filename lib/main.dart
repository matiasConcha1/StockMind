import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/app/app.dart';
import 'package:stockmind/core/services/alert_service.dart';
import 'package:stockmind/core/services/notification_service.dart';
import 'package:stockmind/core/theme/theme_provider.dart';
import 'package:stockmind/core/utils/firebase_bootstrap.dart';
import 'package:stockmind/core/services/storage_service.dart';
import 'package:stockmind/features/alerts/data/services/stock_alert_service.dart';
import 'package:stockmind/features/alerts/providers/alerts_provider.dart';
import 'package:stockmind/features/auth/data/services/auth_service.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
import 'package:stockmind/features/dashboard/data/services/stock_movement_service.dart';
import 'package:stockmind/features/dashboard/data/services/stock_service.dart';
import 'package:stockmind/features/dashboard/providers/dashboard_provider.dart';
import 'package:stockmind/features/locations/data/services/location_service.dart';
import 'package:stockmind/features/locations/providers/locations_provider.dart';
import 'package:stockmind/features/products/data/services/product_service.dart';
import 'package:stockmind/features/products/providers/products_provider.dart';
import 'package:stockmind/features/users/providers/user_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('main: application startup');

  late final FirebaseBootstrapResult bootstrap;
  try {
    debugPrint('main: initializing Firebase');
    bootstrap = await FirebaseBootstrap.initialize();
  } catch (error, stackTrace) {
    debugPrint('main: unexpected Firebase initialization error -> $error');
    debugPrint('$stackTrace');
    bootstrap = FirebaseBootstrapResult(
      isReady: false,
      error: error.toString(),
    );
  }

  final themeProvider = ThemeProvider();
  await themeProvider.load();
  debugPrint('main: theme loaded');

  final storageService = StorageService();
  final stockAlertService = StockAlertService();
  final authProvider = AuthProvider(AuthService())..start();
  final alertService = AlertService(stockAlertService: stockAlertService);
  final userProvider = UserProvider(authProvider: authProvider);
  final notificationService = NotificationService(authProvider: authProvider);
  final productsProvider = ProductsProvider(
    authProvider: authProvider,
    productService: ProductService(),
    storageService: storageService,
    alertService: alertService,
  );
  final locationsProvider = LocationsProvider(
    authProvider: authProvider,
    productsProvider: productsProvider,
    locationService: LocationService(),
    storageService: storageService,
  );
  final alertsProvider = AlertsProvider(
    authProvider: authProvider,
    alertService: alertService,
  );
  final dashboardProvider = DashboardProvider(
    authProvider: authProvider,
    productsProvider: productsProvider,
    locationsProvider: locationsProvider,
    alertsProvider: alertsProvider,
    stockService: StockService(),
    stockMovementService: StockMovementService(),
  );

  debugPrint('main: running app');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(create: (_) => themeProvider),
        Provider<StorageService>.value(value: storageService),
        Provider<AlertService>.value(value: alertService),
        ChangeNotifierProvider<AuthProvider>(create: (_) => authProvider),
        ChangeNotifierProvider<UserProvider>(create: (_) => userProvider),
        ChangeNotifierProvider<NotificationService>.value(
          value: notificationService,
        ),
        ChangeNotifierProvider<ProductsProvider>(create: (_) => productsProvider),
        ChangeNotifierProvider<LocationsProvider>(create: (_) => locationsProvider),
        ChangeNotifierProvider<AlertsProvider>(create: (_) => alertsProvider),
        ChangeNotifierProvider<DashboardProvider>(create: (_) => dashboardProvider),
      ],
      child: StockMindApp(bootstrap: bootstrap),
    ),
  );
}
