import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/core/widgets/permission_guard.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/dashboard_frame.dart';
import 'package:stockmind/features/users/providers/user_provider.dart';

class AdminPlaceholderScreen extends StatelessWidget {
  const AdminPlaceholderScreen({
    required this.title,
    required this.subtitle,
    required this.icon,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DashboardFrame(
      title: title,
      subtitle: subtitle,
      child: PermissionGuard(
        allowed: context.watch<UserProvider>().isAdmin,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(icon, color: colorScheme.primary, size: 34),
                ),
                const SizedBox(height: 18),
                Text(
                  'Panel en construcción',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Esta sección ya quedó protegida para administradores. Puedes conectarla al módulo definitivo sin tocar la navegación actual.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.74),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
