import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/app/routes.dart';
import 'package:stockmind/core/theme/theme_provider.dart';
import 'package:stockmind/features/auth/data/models/app_user.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/dashboard_frame.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _photoUrlController = TextEditingController();

  String? _lastSyncedUserId;
  String? _lastSyncedDisplayName;
  String? _lastSyncedPhotoUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = auth.user;
    _syncControllers(user);

    return DashboardFrame(
      title: 'Perfil y configuración',
      subtitle: 'Administra tu cuenta, seguridad y preferencias visuales.',
      child: Column(
        children: [
          _buildProfileSection(
            context: context,
            user: user,
            auth: auth,
          ),
          const SizedBox(height: 16),
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

  Widget _buildProfileSection({
    required BuildContext context,
    required AppUser? user,
    required AuthProvider auth,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 860;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Perfil', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Actualiza tu identidad visible y revisa los datos principales de tu cuenta.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 20),
                if (isCompact) ...[
                  _buildUserSummary(context, user),
                  const SizedBox(height: 20),
                  _buildProfileForm(context, auth, user),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: _buildUserSummary(context, user),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        flex: 6,
                        child: _buildProfileForm(context, auth, user),
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserSummary(BuildContext context, AppUser? user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formatter = DateFormat('d MMM y', 'es');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ProfileAvatar(photoUrl: user?.photoUrl, initials: _initialsFor(user)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'Usuario StockMind',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? 'Sin correo disponible',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _InfoTile(
                icon: Icons.login_rounded,
                label: 'Acceso',
                value: user?.providerLabel ?? 'Email',
              ),
              _InfoTile(
                icon: Icons.event_rounded,
                label: 'Cuenta creada',
                value: user?.createdAt == null
                    ? 'Sin fecha'
                    : formatter.format(user!.createdAt ?? DateTime.now()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm(
    BuildContext context,
    AuthProvider auth,
    AppUser? user,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre visible',
              prefixIcon: Icon(Icons.badge_rounded),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingresa un nombre visible.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            initialValue: user?.email ?? '',
            enabled: false,
            decoration: const InputDecoration(
              labelText: 'Correo',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _photoUrlController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Foto URL',
              hintText: 'https://...',
              prefixIcon: Icon(Icons.image_outlined),
            ),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) return null;
              final uri = Uri.tryParse(trimmed);
              if (uri == null || !uri.hasAbsolutePath || uri.scheme.isEmpty) {
                return 'Ingresa una URL válida.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.18),
              ),
            ),
            child: Text(
              'Los cambios se sincronizan con tu cuenta y con users/{uid} en Firestore.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.78),
                  ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: auth.isLoading ? null : () => _saveProfile(context, auth),
              icon: auth.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(auth.isLoading ? 'Guardando...' : 'Guardar cambios'),
            ),
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
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
                            'Restablecer contraseña',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enviaremos un correo a ${user?.email ?? ''} para crear una nueva contraseña.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.72),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonalIcon(
                            onPressed: auth.isLoading || user?.email.isEmpty != false
                                ? null
                                : () => _sendPasswordReset(context, auth, user!.email),
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
                          'Cerrar sesión',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Finaliza la sesión actual en este dispositivo y vuelve al acceso principal.',
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
                          label: const Text('Cerrar sesión'),
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

  Future<void> _saveProfile(BuildContext context, AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await auth.updateProfile(
      displayName: _nameController.text.trim(),
      photoUrl: _photoUrlController.text.trim(),
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Perfil actualizado correctamente.'
              : (auth.error ?? 'No fue posible actualizar el perfil.'),
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Te enviamos un correo para restablecer tu contraseña.'
              : (auth.error ?? 'No fue posible enviar el correo.'),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, AuthProvider auth) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          title: const Text('Cerrar sesión'),
          content: const Text('¿Seguro que quieres cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sí, cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;
    await auth.signOut();
    if (!context.mounted) return;
    context.go(AppRoutePaths.login);
  }

  void _syncControllers(AppUser? user) {
    if (user == null) return;
    if (_lastSyncedUserId == user.id &&
        _lastSyncedDisplayName == user.displayName &&
        _lastSyncedPhotoUrl == user.photoUrl) {
      return;
    }

    _nameController.text = user.displayName;
    _photoUrlController.text = user.photoUrl ?? '';
    _lastSyncedUserId = user.id;
    _lastSyncedDisplayName = user.displayName;
    _lastSyncedPhotoUrl = user.photoUrl;
  }

  String _initialsFor(AppUser? user) {
    final source = user?.displayName.trim();
    if (source == null || source.isEmpty) return 'SM';
    final parts = source.split(RegExp(r'\s+')).where((item) => item.isNotEmpty);
    final letters = parts.take(2).map((item) => item[0].toUpperCase()).join();
    return letters.isEmpty ? 'SM' : letters;
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.photoUrl,
    required this.initials,
  });

  final String? photoUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalizedUrl = photoUrl?.trim();
    final hasImage = normalizedUrl != null && normalizedUrl.isNotEmpty;

    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: hasImage
            ? Image.network(
                normalizedUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _AvatarFallback(initials: initials),
              )
            : _AvatarFallback(initials: initials),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 240),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.68),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.labelLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
