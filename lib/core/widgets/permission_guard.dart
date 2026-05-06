import 'package:flutter/material.dart';

class PermissionGuard extends StatelessWidget {
  const PermissionGuard({
    required this.allowed,
    required this.child,
    this.message,
    super.key,
  });

  final bool allowed;
  final Widget child;
  final String? message;

  @override
  Widget build(BuildContext context) {
    if (allowed) return child;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: colorScheme.error.withValues(alpha: 0.20),
                ),
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                color: colorScheme.error,
                size: 32,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Acceso restringido',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message ?? 'No tienes permisos para acceder a esta sección.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.72),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
