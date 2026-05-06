import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/app/routes.dart';
import 'package:stockmind/core/services/app_config_service.dart';
import 'package:stockmind/core/services/notification_service.dart';
import 'package:stockmind/core/services/pwa_service.dart';
import 'package:stockmind/core/theme/theme_provider.dart';
import 'package:stockmind/core/widgets/app_alert_dialog.dart';
import 'package:stockmind/features/auth/data/models/app_user.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/dashboard_frame.dart';
import 'package:stockmind/features/users/providers/user_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AppConfigService _appConfigService = AppConfigService();
  bool _isUpdatingAutoArchive = false;
  bool? _pendingAutoArchiveValue;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final notificationService = context.watch<NotificationService>();
    final pwaService = context.watch<PwaService>();
    final userProvider = context.watch<UserProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = userProvider.currentUser ?? auth.user;
    final width = MediaQuery.sizeOf(context).width;
    final spacing = width < 768 ? 14.0 : 16.0;

    return DashboardFrame(
      title: 'Perfil y configuración',
      subtitle: 'Administra tu cuenta, seguridad y preferencias visuales.',
      child: Column(
        children: [
          _buildAppearanceSection(
            context: context,
            themeProvider: themeProvider,
          ),
          SizedBox(height: spacing),
          _buildSecuritySection(
            context: context,
            user: user,
            auth: auth,
          ),
          SizedBox(height: spacing),
          _buildPwaSection(
            context: context,
            pwaService: pwaService,
          ),
          SizedBox(height: spacing),
          _buildNotificationsSection(
            context: context,
            notificationService: notificationService,
          ),
          if (userProvider.isAdmin) ...[
            SizedBox(height: spacing),
            _buildAutoArchiveSection(context),
            SizedBox(height: spacing),
            _buildAdminSection(context),
          ],
        ],
      ),
    );
  }

  Widget _buildPwaSection({
    required BuildContext context,
    required PwaService pwaService,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 768;
    final padding = isMobile ? 18.0 : 24.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('App instalada', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Instala StockMind para abrirlo como app real, con mejor experiencia móvil y acceso rápido.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          pwaService.isInstalled
                              ? Icons.check_circle_outline_rounded
                              : Icons.install_mobile_rounded,
                          color: pwaService.isInstalled
                              ? colorScheme.secondary
                              : colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pwaService.isInstalled
                                  ? 'App instalada'
                                  : 'Instalar StockMind',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pwaService.installHelpText,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.72),
                              ),
                            ),
                            if (pwaService.updateAvailable) ...[
                              const SizedBox(height: 10),
                              Text(
                                'Nueva versión disponible. Puedes actualizarla ahora.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (pwaService.canInstall)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => pwaService.promptInstall(),
                        icon: const Icon(Icons.download_for_offline_rounded),
                        label: const Text('Instalar StockMind'),
                      ),
                    )
                  else if (pwaService.updateAvailable)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: () => pwaService.applyUpdate(),
                        icon: const Icon(Icons.system_update_rounded),
                        label: const Text('Actualizar ahora'),
                      ),
                    )
                  else if (pwaService.showIosInstallHint || pwaService.showManualInstallHint)
                    Text(
                      pwaService.installHelpText,
                      style: theme.textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoArchiveSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 768;
    final padding = isMobile ? 18.0 : 24.0;

    return StreamBuilder<AppSettingsSnapshot>(
      stream: _appConfigService.watchSettings(),
      builder: (context, snapshot) {
        final settings =
            snapshot.data ??
            const AppSettingsSnapshot(autoArchiveExpiredProducts: false);
        final currentValue =
            _pendingAutoArchiveValue ?? settings.autoArchiveExpiredProducts;
        final isSaving = _isUpdatingAutoArchive ||
            (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData);

        return Card(
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Archivado automático',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Cuando está activo, StockMind archivará automáticamente los productos vencidos durante la revisión diaria.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 18),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.24,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: colorScheme.error,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Archivar productos vencidos automáticamente',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentValue
                                  ? 'Activo para la revisión diaria del sistema.'
                                  : 'Desactivado por seguridad. Los productos vencidos no se archivarán solos.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.72,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: currentValue,
                        onChanged: isSaving
                            ? null
                            : (value) async {
                                await _updateAutoArchiveSetting(
                                  context,
                                  value,
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
      },
    );
  }

  Future<void> _updateAutoArchiveSetting(
    BuildContext context,
    bool value,
  ) async {
    setState(() {
      _isUpdatingAutoArchive = true;
      _pendingAutoArchiveValue = value;
    });

    try {
      await _appConfigService.updateAutoArchiveExpiredProducts(value);
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        'SettingsScreen._updateAutoArchiveSetting FirebaseException: ${error.code} ${error.message}',
      );
      debugPrint('$stackTrace');
      if (!context.mounted) return;
      await showAppAlertDialog(
        context,
        type: AppAlertType.error,
        title: 'No se pudo actualizar',
        message: _mapAppConfigError(error),
      );
    } catch (error, stackTrace) {
      debugPrint('SettingsScreen._updateAutoArchiveSetting error: $error');
      debugPrint('$stackTrace');
      if (!context.mounted) return;
      await showAppAlertDialog(
        context,
        type: AppAlertType.error,
        title: 'No se pudo actualizar',
        message: 'Ocurrió un error inesperado al guardar esta configuración.',
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isUpdatingAutoArchive = false;
        _pendingAutoArchiveValue = null;
      });
    }
  }

  String _mapAppConfigError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'No tienes permisos para cambiar esta configuración. Revisa tu rol y despliega las reglas de Firestore.';
      case 'unavailable':
        return 'Firebase no está disponible en este momento. Intenta nuevamente.';
      case 'failed-precondition':
        return 'La configuración no pudo guardarse por una restricción de Firestore.';
      default:
        return error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'No pudimos guardar esta configuración.';
    }
  }

  Widget _buildNotificationsSection({
    required BuildContext context,
    required NotificationService notificationService,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 768;
    final padding = isMobile ? 18.0 : 24.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notificaciones', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Activa avisos push para stock bajo, productos próximos a vencer y vencidos.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 18),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.notifications_active_outlined,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alertas push',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notificationService.notificationStatusLabel,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.72),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Recibe avisos cuando un producto esté por vencer, vencido, con stock bajo o cuando existan reposiciones pendientes.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.72),
                              ),
                            ),
                            if (notificationService.token != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Token guardado correctamente en este dispositivo.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                            if (notificationService.error != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                notificationService.error!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.error,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: notificationService.isLoading
                            ? null
                            : () => notificationService.setNotificationsEnabled(true),
                        icon: const Icon(Icons.notifications_active_outlined),
                        label: const Text('Activar notificaciones'),
                      ),
                      OutlinedButton.icon(
                        onPressed: notificationService.isLoading
                            ? null
                            : () => notificationService.setNotificationsEnabled(false),
                        icon: const Icon(Icons.notifications_off_outlined),
                        label: const Text('Desactivar'),
                      ),
                      TextButton.icon(
                        onPressed: notificationService.isLoading
                            ? null
                            : () async {
                                await notificationService.resetDeferredPrompt();
                                await notificationService.setNotificationsEnabled(true);
                              },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Volver a solicitar permiso'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSection({
    required BuildContext context,
    required ThemeProvider themeProvider,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final padding = width < 768 ? 18.0 : 24.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apariencia', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Elige cómo quieres ver tu panel en este dispositivo.',
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 768;
    final padding = isMobile ? 18.0 : 24.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seguridad y sesión', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Gestiona el acceso de tu cuenta y las acciones sensibles.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 18),
            if (user?.isEmailProvider ?? false)
              _InfoActionCard(
                icon: Icons.lock_reset_rounded,
                iconColor: colorScheme.secondary,
                iconBackground: colorScheme.secondary.withValues(alpha: 0.12),
                title: 'Restablecer contraseña',
                description:
                    'Enviaremos un correo a ${user?.email ?? ''} para crear una nueva contraseña.',
                action: FilledButton.tonalIcon(
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
              ),
            if (user?.isEmailProvider ?? false) const SizedBox(height: 16),
            _InfoActionCard(
              icon: Icons.logout_rounded,
              iconColor: colorScheme.error,
              iconBackground: colorScheme.error.withValues(alpha: 0.12),
              title: 'Cerrar sesión',
              description:
                  'Finaliza la sesión actual en este dispositivo y vuelve al acceso principal.',
              decorationColor: colorScheme.error.withValues(alpha: 0.08),
              decorationBorder:
                  colorScheme.error.withValues(alpha: 0.20),
              action: isMobile
                  ? SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: auth.isLoading
                            ? null
                            : () => _confirmSignOut(context, auth),
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Cerrar sesión'),
                      ),
                    )
                  : OutlinedButton.icon(
                      onPressed: auth.isLoading
                          ? null
                          : () => _confirmSignOut(context, auth),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Cerrar sesión'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final padding = width < 768 ? 18.0 : 24.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Administración', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Accesos avanzados reservados para administradores del sistema.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 18),
            _AdminLinkCard(
              title: 'Usuarios',
              description: 'Gestiona usuarios y permisos del sistema.',
              icon: Icons.group_outlined,
              onTap: () => context.go(AppRoutePaths.users),
            ),
            const SizedBox(height: 14),
            _AdminLinkCard(
              title: 'Historial de actividad',
              description: 'Revisa movimientos recientes del sistema.',
              icon: Icons.history_rounded,
              onTap: () => context.go(AppRoutePaths.activity),
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
    if (context.mounted) {
      context.read<UserProvider>().clear();
    }
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

class _InfoActionCard extends StatelessWidget {
  const _InfoActionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.description,
    required this.action,
    this.decorationColor,
    this.decorationBorder,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String description;
  final Widget action;
  final Color? decorationColor;
  final Color? decorationBorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 768;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: decorationColor ??
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: decorationBorder ?? colorScheme.outlineVariant,
        ),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoActionHeader(
                  icon: icon,
                  iconColor: iconColor,
                  iconBackground: iconBackground,
                  title: title,
                  description: description,
                ),
                const SizedBox(height: 14),
                SizedBox(width: double.infinity, child: action),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _InfoActionHeader(
                    icon: icon,
                    iconColor: iconColor,
                    iconBackground: iconBackground,
                    title: title,
                    description: description,
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(child: action),
              ],
            ),
    );
  }
}

class _InfoActionHeader extends StatelessWidget {
  const _InfoActionHeader({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminLinkCard extends StatelessWidget {
  const _AdminLinkCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.arrow_forward_rounded,
              color: colorScheme.onSurface.withValues(alpha: 0.58),
            ),
          ],
        ),
      ),
    );
  }
}
