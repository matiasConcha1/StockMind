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
import 'package:stockmind/core/widgets/app_alert_dialog.dart';
import 'package:stockmind/core/widgets/firebase_setup_screen.dart';
import 'package:stockmind/features/company/providers/company_profile_provider.dart';
import 'package:stockmind/features/company/presentation/widgets/initial_onboarding_dialog.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
import 'package:stockmind/features/users/providers/user_provider.dart';

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
  bool _notificationPromptShownThisSession = false;
  bool _onboardingShownThisSession = false;
  late final VoidCallback _pwaListener;
  PwaService? _pwaService;
  Timer? _notificationPromptTimer;
  Timer? _onboardingTimer;
  late final AuthProvider _authProvider;
  late final NotificationService _notificationService;
  late final UserProvider _userProvider;
  late final CompanyProfileProvider _companyProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = context.read<AuthProvider>();
    _notificationService = context.read<NotificationService>();
    _userProvider = context.read<UserProvider>();
    _companyProvider = context.read<CompanyProfileProvider>();
    _router = AppRoutes.createRouter(
      authProvider: _authProvider,
    );
    _messageSubscription =
        _notificationService.foregroundMessages.listen((message) {
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
    _authProvider.addListener(_handleNotificationPromptState);
    _notificationService.addListener(_handleNotificationPromptState);
    _userProvider.addListener(_handleOnboardingState);
    _companyProvider.addListener(_handleOnboardingState);
    _router.routeInformationProvider.addListener(_handleNotificationPromptState);
    _router.routeInformationProvider.addListener(_handleOnboardingState);
    _handleNotificationPromptState();
    _handleOnboardingState();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _notificationPromptTimer?.cancel();
    _onboardingTimer?.cancel();
    _authProvider.removeListener(_handleNotificationPromptState);
    _notificationService.removeListener(_handleNotificationPromptState);
    _userProvider.removeListener(_handleOnboardingState);
    _companyProvider.removeListener(_handleOnboardingState);
    _router.routeInformationProvider.removeListener(_handleNotificationPromptState);
    _router.routeInformationProvider.removeListener(_handleOnboardingState);
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

  void _handleNotificationPromptState() {
    final isAuthenticated = _authProvider.isAuthenticated;
    final currentPath = _router.routeInformationProvider.value.uri.path;
    final onPrivateArea = currentPath != AppRoutePaths.login &&
        currentPath != AppRoutePaths.register &&
        currentPath != AppRoutePaths.forgotPassword &&
        currentPath != AppRoutePaths.loading;

    if (!isAuthenticated) {
      _notificationPromptTimer?.cancel();
      _notificationPromptShownThisSession = false;
      return;
    }

    if (_notificationPromptShownThisSession ||
        !_notificationService.canPromptForNotifications ||
        !onPrivateArea) {
      _notificationPromptTimer?.cancel();
      return;
    }

    if (_notificationPromptTimer?.isActive ?? false) {
      return;
    }

    _notificationPromptTimer = Timer(const Duration(seconds: 4), () async {
      if (!mounted ||
          _notificationPromptShownThisSession ||
          !_authProvider.isAuthenticated ||
          !_notificationService.canPromptForNotifications) {
        return;
      }

      _notificationPromptShownThisSession = true;
      final accepted = await showAppAlertDialog(
        context,
        type: AppAlertType.confirm,
        title: 'Activa las notificaciones',
        message:
            'Recibe alertas de stock bajo, productos por vencer y reposiciones pendientes.',
        confirmLabel: 'Activar notificaciones',
        cancelLabel: 'Ahora no',
      );
      if (!mounted) return;
      if (accepted == true) {
        await _notificationService.resetDeferredPrompt();
        await _notificationService.setNotificationsEnabled(true);
      } else {
        await _notificationService.deferPrompt();
      }
    });
  }

  void _handleOnboardingState() {
    final isAuthenticated = _authProvider.isAuthenticated;
    final currentPath = _router.routeInformationProvider.value.uri.path;
    final onPrivateArea = currentPath != AppRoutePaths.login &&
        currentPath != AppRoutePaths.register &&
        currentPath != AppRoutePaths.forgotPassword &&
        currentPath != AppRoutePaths.loading;

    if (!isAuthenticated) {
      _onboardingTimer?.cancel();
      _onboardingShownThisSession = false;
      return;
    }

    final needsOnboarding = !_userProvider.hasCompletedOnboarding ||
        (_userProvider.isAdmin && !_companyProvider.isComplete);
    if (_onboardingShownThisSession ||
        !needsOnboarding ||
        !onPrivateArea ||
        _userProvider.isLoading ||
        _companyProvider.isLoading) {
      _onboardingTimer?.cancel();
      return;
    }

    if (_onboardingTimer?.isActive ?? false) return;

    _onboardingTimer = Timer(const Duration(seconds: 2), () async {
      if (!mounted ||
          _onboardingShownThisSession ||
          !_authProvider.isAuthenticated ||
          (_userProvider.hasCompletedOnboarding && _companyProvider.isComplete)) {
        return;
      }
      _onboardingShownThisSession = true;
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const InitialOnboardingDialog(),
      );
    });
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
        builder: _buildClampedTextScale,
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
      builder: _buildClampedTextScale,
      routerConfig: _router,
    );
  }

  Widget _buildClampedTextScale(BuildContext context, Widget? child) {
    final mediaQuery = MediaQuery.of(context);
    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: TextScaler.linear(
          mediaQuery.textScaler.scale(1.0).clamp(0.9, 1.0),
        ),
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }
}
