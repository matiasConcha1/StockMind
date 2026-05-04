import 'package:flutter/material.dart';
import 'package:stockmind/core/theme/app_theme.dart';

class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({
    required this.errorMessage,
    super.key,
  });

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              theme.brightness == Brightness.dark
                  ? const Color(0xFF07101E)
                  : const Color(0xFFE8F0FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppTheme.brand.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.cloud_sync_rounded,
                        color: AppTheme.brand,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Firebase no está configurado todavía',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'La aplicación ya está preparada para Firebase Auth y Firestore, pero este proyecto necesita credenciales reales antes de iniciar sesión y sincronizar inventario.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Pasos recomendados:',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text('1. Ejecuta `flutterfire configure`.'),
                    const Text(
                      '2. Habilita Email/Password y Google en Firebase Authentication.',
                    ),
                    const Text('3. Crea la base de datos Cloud Firestore.'),
                    const Text('4. Vuelve a ejecutar la app.'),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 20),
                      SelectableText(
                        errorMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
