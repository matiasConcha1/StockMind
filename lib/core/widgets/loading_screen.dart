import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/app/routes.dart';
import 'package:stockmind/core/widgets/section_card.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  Timer? _timer;
  bool _showFallback = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() => _showFallback = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final messages = <String>[
      'Inicializando Firebase...',
      'Verificando sesión...',
      if (!authProvider.isLoading)
        authProvider.isAuthenticated ? 'Redirigiendo...' : 'Ir al login...',
    ];

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SectionCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 24),
                  Text(
                    'Cargando StockMind',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  for (final message in messages) ...[
                    Text(message),
                    const SizedBox(height: 6),
                  ],
                  if (authProvider.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      authProvider.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  if (_showFallback) ...[
                    const SizedBox(height: 20),
                    FilledButton.tonal(
                      onPressed: () {
                        context.read<AuthProvider>().completeLoadingFallback();
                        context.go(AppRoutePaths.login);
                      },
                      child: const Text('Ir al login'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
