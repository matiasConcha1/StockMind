import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/app/routes.dart';
import 'package:stockmind/core/theme/app_theme.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';

class StockMindLoadingScreen extends StatefulWidget {
  const StockMindLoadingScreen({super.key});

  @override
  State<StockMindLoadingScreen> createState() => _StockMindLoadingScreenState();
}

class _StockMindLoadingScreenState extends State<StockMindLoadingScreen> {
  static const _statusMessages = [
    'Verificando sesión...',
    'Conectando con Firebase...',
    'Preparando tu inventario...',
  ];

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
        _messageIndex = (_messageIndex + 1) % _statusMessages.length;
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
    final theme = Theme.of(context);
    final statusMessage = authProvider.error ??
        (!authProvider.isLoading
            ? authProvider.isAuthenticated
                ? 'Redirigiendo...'
                : 'Preparando acceso...'
            : _statusMessages[_messageIndex]);

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
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 36,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(36),
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
                          Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(
                              Icons.insights_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                          ).animate().fadeIn(duration: 280.ms).scale(),
                          const SizedBox(height: 22),
                          Text(
                            'StockMind',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Preparando tu inventario...',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.82),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.6,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.08),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: Text(
                              statusMessage,
                              key: ValueKey(statusMessage),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: authProvider.error != null
                                    ? const Color(0xFFFCA5A5)
                                    : Colors.white.withValues(alpha: 0.74),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 5,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.10),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withValues(alpha: 0.88),
                              ),
                            ),
                          ),
                          if (_showFallback) ...[
                            const SizedBox(height: 24),
                            Text(
                              'Esto está tardando más de lo normal',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.84),
                              ),
                            ),
                            const SizedBox(height: 14),
                            FilledButton.tonal(
                              onPressed: () {
                                context
                                    .read<AuthProvider>()
                                    .completeLoadingFallback();
                                context.go(AppRoutePaths.login);
                              },
                              style: FilledButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.12),
                              ),
                              child: const Text('Ir al login'),
                            ),
                          ],
                        ],
                      ),
                    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.04, end: 0),
                  ),
                ),
              ),
            ),
          ],
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
