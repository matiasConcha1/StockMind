import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/controllers/auth_controller.dart';
import 'package:stockmind/controllers/inventory_controller.dart';
import 'package:stockmind/controllers/theme_controller.dart';
import 'package:stockmind/core/router/app_router.dart';
import 'package:stockmind/core/theme/app_theme.dart';
import 'package:stockmind/services/auth_service.dart';
import 'package:stockmind/services/inventory_service.dart';

class StockMindApp extends StatefulWidget {
  const StockMindApp({super.key});

  @override
  State<StockMindApp> createState() => _StockMindAppState();
}

class _StockMindAppState extends State<StockMindApp> {
  late final AuthController _authController;
  late final ThemeController _themeController;
  late final InventoryController _inventoryController;
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    final authService = AuthService();
    final inventoryService = InventoryService();
    _authController = AuthController(authService);
    _themeController = ThemeController();
    _inventoryController = InventoryController(inventoryService);
    _appRouter = AppRouter(authController: _authController);
  }

  @override
  void dispose() {
    _appRouter.dispose();
    _inventoryController.dispose();
    _themeController.dispose();
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: _authController),
        ChangeNotifierProvider<ThemeController>.value(value: _themeController),
        ChangeNotifierProvider<InventoryController>.value(
          value: _inventoryController,
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'StockMind',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeController.themeMode,
            routerConfig: _appRouter.router,
          );
        },
      ),
    );
  }
}
