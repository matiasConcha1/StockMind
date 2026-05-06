import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/app/routes.dart';
import 'package:stockmind/core/constants/app_constants.dart';
import 'package:stockmind/core/services/notification_service.dart';
import 'package:stockmind/core/services/pwa_service.dart';
import 'package:stockmind/core/theme/app_theme.dart';
import 'package:stockmind/core/theme/theme_provider.dart';
import 'package:stockmind/core/utils/firebase_bootstrap.dart';
import 'package:stockmind/core/widgets/firebase_setup_screen.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';

class StockMindApp extends StatefulWidget {
  const StockMindApp({
    required this.bootstrap,
    super.key,
  });

  final FirebaseBootstrapResult bootstrap;

  @override
  State<StockMindApp> createState() => _StockMindAppState();
}

class _StockMindAppState extends State<StockMindApp> {
  late final GoRouter _router;
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<RemoteMessage>? _messageSubscription;
  bool _updateBannerVisible = false;
  late final VoidCallback _pwaListener;
  PwaService? _pwaService;

  @override
  void initState() {
    super.initState();
    _router = AppRoutes.createRouter(
      authProvider: context.read<AuthProvider>(),
    );
    _messageSubscription =
        context.read<NotificationService>().foregroundMessages.listen((message) {
      final title = message.notification?.title?.trim();
      final body = message.notification?.body?.trim();
      final text = [
        if (title != null && title.isNotEmpty) title,
        if (body != null && body.isNotEmpty) body,
      ].join(' · ');
      final messenger = _messengerKey.currentState;
      if (messenger == null || text.isEmpty) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));
    });
    _pwaListener = _handlePwaStateChanged;
    _pwaService = context.read<PwaService>();
    _pwaService?.addListener(_pwaListener);
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _pwaService?.removeListener(_pwaListener);
    _router.dispose();
    super.dispose();
  }

  void _handlePwaStateChanged() {
    final messenger = _messengerKey.currentState;
    if (messenger == null) return;

    final pwaService = _pwaService;
    if (pwaService == null) return;
    if (pwaService.updateAvailable) {
      if (_updateBannerVisible) return;
      _updateBannerVisible = true;
      messenger
        ..hideCurrentMaterialBanner()
        ..showMaterialBanner(
          MaterialBanner(
            content: const Text('Nueva versión disponible'),
            leading: const Icon(Icons.system_update_rounded),
            actions: [
              TextButton(
                onPressed: () async {
                  messenger.hideCurrentMaterialBanner();
                  _updateBannerVisible = false;
                  await pwaService.applyUpdate();
                },
                child: const Text('Actualizar ahora'),
              ),
            ],
          ),
        );
      return;
    }

    if (_updateBannerVisible) {
      _updateBannerVisible = false;
      messenger.hideCurrentMaterialBanner();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    if (!widget.bootstrap.isReady) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppConstants.appName,
        scaffoldMessengerKey: _messengerKey,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeProvider.themeMode,
        home: FirebaseSetupScreen(errorMessage: widget.bootstrap.error),
      );
    }

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      scaffoldMessengerKey: _messengerKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: _router,
    );
  }
}
