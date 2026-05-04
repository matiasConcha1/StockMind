import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/controllers/auth_controller.dart';
import 'package:stockmind/controllers/theme_controller.dart';
import 'package:stockmind/core/utils/responsive.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onMenuPressed,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onMenuPressed;

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final themeController = context.watch<ThemeController>();
    final theme = Theme.of(context);

    return Row(
      children: [
        if (!Responsive.isDesktop(context))
          IconButton(
            onPressed: onMenuPressed,
            icon: const Icon(Icons.menu_rounded),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            final isDark = theme.brightness == Brightness.dark;
            themeController.setThemeMode(
              isDark ? ThemeMode.light : ThemeMode.dark,
            );
          },
          icon: Icon(
            theme.brightness == Brightness.dark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(18),
            border:
                Border.all(color: theme.dividerColor.withValues(alpha: 0.7)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.15),
                foregroundColor: theme.colorScheme.primary,
                child: const Icon(Icons.person_rounded),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(authController.currentUser?.name ?? 'Usuario'),
                  Text(
                    authController.currentUser?.userTypeLabel ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
