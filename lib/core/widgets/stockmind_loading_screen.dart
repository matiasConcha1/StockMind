import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/app/routes.dart';
import 'package:stockmind/core/i18n/app_strings.dart';
import 'package:stockmind/core/theme/app_theme.dart';
import 'package:stockmind/core/widgets/language_selector.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';

class StockMindLoadingScreen extends StatefulWidget {
  const StockMindLoadingScreen({super.key});

  @override
  State<StockMindLoadingScreen> createState() => _StockMindLoadingScreenState();
}

class _StockMindLoadingScreenState extends State<StockMindLoadingScreen> {
  Timer? _fallbackTimer;
  Timer? _messageTimer;
  bool _showFallback = false;
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    _fallbackTimer = Timer(const Duration(seconds: 8), () {
      if (!mounted) return;
      setState(() => _showFallback = true);
    });
    _messageTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() {
        _messageIndex = (_messageIndex + 1) % 3;
      });
    });
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final strings = context.strings;
    final statusMessages = [
      strings.checkingSession,
      strings.connectingFirebase,
      strings.preparingInventory,
    ];
    final statusMessage = authProvider.error ??
        (!authProvider.isLoading
            ? authProvider.isAuthenticated
                ? strings.redirecting
                : strings.preparingAccess
            : statusMessages[_messageIndex]);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF07111F),
              Color(0xFF0F1C34),
              Color(0xFF1D4ED8),
              Color(0xFF7C3AED),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -110,
              right: -30,
              child: _AmbientGlow(
                size: 260,
                color: AppTheme.brandViolet,
                opacity: 0.18,
              ),
            ),
            const Positioned(
              bottom: -90,
              left: -20,
              child: _AmbientGlow(
                size: 220,
                color: AppTheme.brand,
                opacity: 0.16,
              ),
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Align(
                        alignment: Alignment.centerRight,
                        child: LanguageSelector(compact: true),
                      ),
                      const SizedBox(height: 12),
                      StockMindLoadingPanel(
                        statusMessage: statusMessage,
                        primaryMessage: strings.preparingInventoryWorkspace,
                        secondaryMessage: strings.syncingSessionAndTheme,
                        showFallback: _showFallback,
                        onFallbackPressed: () {
                          context.read<AuthProvider>().completeLoadingFallback();
                          context.go(AppRoutePaths.login);
                        },
                      ),
                    ],
                  ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.04, end: 0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StockMindLoadingPanel extends StatelessWidget {
  const StockMindLoadingPanel({
    required this.statusMessage,
    this.primaryMessage = 'Preparando tu espacio de inventario...',
    this.secondaryMessage =
        'Sincronizando acceso, tema y sesión para abrir tu panel.',
    this.showFallback = false,
    this.onFallbackPressed,
    this.compact = false,
    super.key,
  });

  final String statusMessage;
  final String primaryMessage;
  final String secondaryMessage;
  final bool showFallback;
  final VoidCallback? onFallbackPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final panel = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 24 : 32,
        vertical: compact ? 28 : 36,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(compact ? 28 : 36),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 52,
            spreadRadius: -18,
            offset: const Offset(0, 28),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: compact ? 90 : 100,
            child: Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/logo_icon.png',
                    width: 60,
                    height: 60,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.inventory_2,
                        size: 40,
                        color: Colors.white,
                      );
                    },
                  ),
                ),
              ).animate().fadeIn(duration: 280.ms).scale(
                    begin: const Offset(0.92, 0.92),
                  ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'StockMind',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: Text(
              primaryMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.86),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 18),
            Text(
              secondaryMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.74),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const _LoadingIndicatorRow(),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Text(
              statusMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.80),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const _LoadingProgressBar(),
          if (showFallback) ...[
            const SizedBox(height: 24),
            Text(
              context.strings.thisIsTakingLonger,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.84),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.tonal(
              onPressed: onFallbackPressed,
              style: FilledButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
              ),
              child: Text(context.strings.goToLogin),
            ),
          ],
        ],
      ),
    );

    if (compact) return panel;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 540),
      child: panel,
    );
  }
}

class _LoadingIndicatorRow extends StatelessWidget {
  const _LoadingIndicatorRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _PulseDot(opacity: 0.48, delay: Duration.zero),
        const SizedBox(width: 8),
        _PulseDot(opacity: 0.36, delay: Duration(milliseconds: 180)),
        const SizedBox(width: 8),
        _PulseDot(opacity: 0.26, delay: Duration(milliseconds: 360)),
      ],
    );
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot({
    required this.opacity,
    required this.delay,
  });

  final double opacity;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    )
        .animate(
          delay: delay,
          onPlay: (controller) => controller.repeat(),
        )
        .fadeIn(duration: 700.ms)
        .then()
        .fadeOut(duration: 700.ms);
  }
}

class _LoadingProgressBar extends StatelessWidget {
  const _LoadingProgressBar();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        minHeight: 5,
        backgroundColor: Colors.white.withValues(alpha: 0.10),
        valueColor: AlwaysStoppedAnimation<Color>(
          Colors.white.withValues(alpha: 0.88),
        ),
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: opacity),
        ),
      ),
    );
  }
}
