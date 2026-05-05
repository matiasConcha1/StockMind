import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/app/routes.dart';
import 'package:stockmind/core/theme/theme_provider.dart';
import 'package:stockmind/core/widgets/app_alert_dialog.dart';
import 'package:stockmind/features/auth/data/models/app_user.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/dashboard_frame.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = auth.user;

    return DashboardFrame(
      title: 'Perfil y configuracion',
      subtitle: 'Administra tu cuenta, seguridad y preferencias visuales.',
      child: Column(
        children: [
          _buildAppearanceSection(
            context: context,
            themeProvider: themeProvider,
          ),
          const SizedBox(height: 16),
          _buildSecuritySection(
            context: context,
            user: user,
            auth: auth,
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection({
    required BuildContext context,
    required ThemeProvider themeProvider,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apariencia', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Elige como quieres ver tu panel en este dispositivo.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 18),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? colorScheme.primary.withValues(alpha: 0.10)
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDarkMode
                      ? colorScheme.primary.withValues(alpha: 0.32)
                      : colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? colorScheme.primary.withValues(alpha: 0.14)
                          : colorScheme.secondary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isDarkMode
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: isDarkMode
                          ? colorScheme.primary
                          : colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Modo oscuro',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isDarkMode
                              ? 'Activo en este dispositivo'
                              : 'Usando modo claro',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: isDarkMode,
                    onChanged: (value) {
                      themeProvider.updateThemeMode(
                        value ? ThemeMode.dark : ThemeMode.light,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection({
    required BuildContext context,
    required AppUser? user,
    required AuthProvider auth,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seguridad y sesion', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Gestiona el acceso de tu cuenta y las acciones sensibles.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 18),
            if (user?.isEmailProvider ?? false)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color:
                      colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.lock_reset_rounded,
                        color: colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Restablecer contrasena',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enviaremos un correo a ${user?.email ?? ''} para crear una nueva contrasena.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.72),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonalIcon(
                            onPressed: auth.isLoading || user?.email.isEmpty != false
                                ? null
                                : () => _sendPasswordReset(
                                      context,
                                      auth,
                                      user!.email,
                                    ),
                            icon: const Icon(Icons.mail_outlined),
                            label: Text(
                              auth.isLoading
                                  ? 'Enviando...'
                                  : 'Enviar correo de restablecimiento',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (user?.isEmailProvider ?? false) const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: colorScheme.error.withValues(alpha: 0.20),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.logout_rounded,
                    color: colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cerrar sesion',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Finaliza la sesion actual en este dispositivo y vuelve al acceso principal.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.72),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: auth.isLoading
                              ? null
                              : () => _confirmSignOut(context, auth),
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Cerrar sesion'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendPasswordReset(
    BuildContext context,
    AuthProvider auth,
    String email,
  ) async {
    final success = await auth.sendResetEmail(email);
    if (!context.mounted) return;
    await showAppAlertDialog(
      context,
      type: success ? AppAlertType.success : AppAlertType.error,
      title: success ? 'Correo enviado' : 'No se pudo enviar',
      message: success
          ? 'Te enviamos un correo para restablecer tu contraseña.'
          : (auth.error ??
              'No pudimos completar la operación. Revisa tu conexión e inténtalo nuevamente.'),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, AuthProvider auth) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: '¿Seguro que quieres cerrar sesión?',
      message: 'Tu sesión actual se cerrará en este dispositivo.',
      confirmLabel: 'Cerrar sesión',
      cancelLabel: 'Cancelar',
    );

    if (!confirmed || !context.mounted) return;
    await auth.signOut();
    if (!context.mounted) return;
    if (auth.error != null) {
      await showAppAlertDialog(
        context,
        type: AppAlertType.error,
        title: 'No se pudo cerrar sesión',
        message: auth.error!,
      );
      return;
    }
    context.go(AppRoutePaths.login);
  }
}
