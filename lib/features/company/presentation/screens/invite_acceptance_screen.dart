import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/app/routes.dart';
import 'package:stockmind/core/theme/app_theme.dart';
import 'package:stockmind/core/widgets/app_alert_dialog.dart';
import 'package:stockmind/core/widgets/empty_state.dart';
import 'package:stockmind/core/widgets/section_card.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
import 'package:stockmind/features/company/models/company_invitation.dart';
import 'package:stockmind/features/auth/presentation/widgets/auth_shell.dart';
import 'package:stockmind/features/users/providers/user_provider.dart';

class InviteAcceptanceScreen extends StatefulWidget {
  const InviteAcceptanceScreen({
    required this.inviteToken,
    super.key,
  });

  final String inviteToken;

  @override
  State<InviteAcceptanceScreen> createState() => _InviteAcceptanceScreenState();
}

class _InviteAcceptanceScreenState extends State<InviteAcceptanceScreen> {
  late Future<CompanyInvitation?> _future;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _future = _loadInvitation();
  }

  Future<CompanyInvitation?> _loadInvitation() {
    return context.read<UserProvider>().getInvitationByToken(widget.inviteToken);
  }

  void _refresh() {
    setState(() {
      _future = _loadInvitation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final redirectTarget = '/invite/${widget.inviteToken}';

    if (!authProvider.isAuthenticated) {
      return AuthShell(
        title: 'Invitación de colaboración',
        subtitle:
            'Accede o crea tu cuenta para unirte al workspace compartido de StockMind desde este link.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _InvitePreviewCard(),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.go(
                '${AppRoutePaths.login}?redirect=${Uri.encodeComponent(redirectTarget)}',
              ),
              icon: const Icon(Icons.login_rounded),
              label: const Text('Iniciar sesión para continuar'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.go(
                '${AppRoutePaths.register}?redirect=${Uri.encodeComponent(redirectTarget)}',
              ),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Crear cuenta y unirme'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF071221)
                  : const Color(0xFFF4F7FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: FutureBuilder<CompanyInvitation?>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SectionCard(
                        child: SizedBox(
                          height: 320,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return _InviteStateCard(
                        title: 'No pudimos validar la invitación',
                        subtitle:
                            'Revisa el link o vuelve a intentarlo en unos segundos.',
                        icon: Icons.link_off_rounded,
                        action: FilledButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Reintentar'),
                        ),
                      );
                    }

                    final invitation = snapshot.data;
                    if (invitation == null) {
                      return _InviteStateCard(
                        title: 'Invitación no encontrada',
                        subtitle:
                            'El enlace no coincide con una invitación activa de StockMind.',
                        icon: Icons.search_off_rounded,
                        action: OutlinedButton.icon(
                          onPressed: () => context.go(AppRoutePaths.dashboard),
                          icon: const Icon(Icons.space_dashboard_rounded),
                          label: const Text('Ir al dashboard'),
                        ),
                      );
                    }

                    if (invitation.isExpired) {
                      return _InviteStateCard(
                        title: 'Invitación expirada',
                        subtitle:
                            'Este link ya venció. Pide a un administrador que genere una nueva invitación.',
                        icon: Icons.schedule_send_rounded,
                        action: OutlinedButton.icon(
                          onPressed: () => context.go(AppRoutePaths.dashboard),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Volver'),
                        ),
                      );
                    }

                    if (invitation.isRevoked) {
                      return _InviteStateCard(
                        title: 'Invitación revocada',
                        subtitle:
                            'El administrador desactivó este acceso. Si aún necesitas entrar, solicita un nuevo link.',
                        icon: Icons.block_outlined,
                        action: OutlinedButton.icon(
                          onPressed: () => context.go(AppRoutePaths.dashboard),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Volver'),
                        ),
                      );
                    }

                    if (invitation.isAccepted) {
                      return _InviteStateCard(
                        title: 'Invitación ya aceptada',
                        subtitle:
                            'Este acceso ya fue utilizado. Puedes entrar a tu dashboard y cambiar de empresa desde el selector superior.',
                        icon: Icons.check_circle_outline_rounded,
                        action: FilledButton.icon(
                          onPressed: () => context.go(AppRoutePaths.dashboard),
                          icon: const Icon(Icons.space_dashboard_rounded),
                          label: const Text('Entrar a StockMind'),
                        ),
                      );
                    }

                    return _InviteReadyCard(
                      invitation: invitation,
                      submitting: _submitting,
                      onAccept: _acceptInvitation,
                      onReject: _rejectInvitation,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _acceptInvitation() async {
    setState(() => _submitting = true);
    try {
      await context.read<UserProvider>().acceptInvitationByToken(
            widget.inviteToken,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Te uniste a la empresa correctamente.'),
        ),
      );
      context.go(AppRoutePaths.dashboard);
    } on Exception catch (error) {
      if (!mounted) return;
      await showAppAlertDialog(
        context,
        type: AppAlertType.error,
        title: 'No se pudo aceptar la invitación',
        message: error.toString(),
      );
      _refresh();
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _rejectInvitation() async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: '¿Rechazar invitación?',
      message: 'Este link dejará de estar disponible para tu cuenta.',
      confirmLabel: 'Rechazar',
      cancelLabel: 'Cancelar',
    );
    if (!confirmed || !mounted) return;
    setState(() => _submitting = true);
    try {
      await context.read<UserProvider>().rejectInvitationByToken(
            widget.inviteToken,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La invitación fue rechazada.'),
        ),
      );
      context.go(AppRoutePaths.dashboard);
    } on Exception catch (error) {
      if (!mounted) return;
      await showAppAlertDialog(
        context,
        type: AppAlertType.error,
        title: 'No se pudo rechazar la invitación',
        message: error.toString(),
      );
      _refresh();
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

class _InvitePreviewCard extends StatelessWidget {
  const _InvitePreviewCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.brand, AppTheme.brandViolet],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.group_add_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Únete a una empresa compartida',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            'StockMind validará tu invitación, asociará tu usuario a la empresa correcta y cambiará automáticamente tu workspace activo.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.74),
                ),
          ),
        ],
      ),
    );
  }
}

class _InviteReadyCard extends StatelessWidget {
  const _InviteReadyCard({
    required this.invitation,
    required this.submitting,
    required this.onAccept,
    required this.onReject,
  });

  final CompanyInvitation invitation;
  final bool submitting;
  final Future<void> Function() onAccept;
  final Future<void> Function() onReject;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invitación lista para aceptar',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            'Te invitaron a colaborar en ${invitation.companyName} con el rol ${_roleLabel(invitation.role)}.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _InviteMetaPill(
                icon: Icons.apartment_rounded,
                label: invitation.companyName,
              ),
              _InviteMetaPill(
                icon: Icons.verified_user_outlined,
                label: _roleLabel(invitation.role),
              ),
              _InviteMetaPill(
                icon: Icons.schedule_rounded,
                label: invitation.expiresAt == null
                    ? 'Sin expiración'
                    : 'Expira ${_formatDate(invitation.expiresAt!)}',
              ),
            ],
          ),
          if (invitation.hasEmailRestriction) ...[
            const SizedBox(height: 16),
            Text(
              'Este acceso está asociado a ${invitation.email}. Debes usar esa misma cuenta para aceptarlo.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: submitting ? null : onReject,
                  child: const Text('Rechazar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: submitting ? null : onAccept,
                  icon: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(submitting ? 'Procesando...' : 'Aceptar invitación'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InviteStateCard extends StatelessWidget {
  const _InviteStateCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.action,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: SizedBox(
        height: 320,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: EmptyState(
                title: title,
                subtitle: subtitle,
                icon: icon,
                compact: true,
              ),
            ),
            const SizedBox(height: 8),
            action,
          ],
        ),
      ),
    );
  }
}

class _InviteMetaPill extends StatelessWidget {
  const _InviteMetaPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

String _roleLabel(String role) {
  switch (role.trim().toLowerCase()) {
    case 'admin':
      return 'Administrador';
    case 'editor':
      return 'Editor';
    case 'operator':
      return 'Operador';
    case 'viewer':
      return 'Visualizador';
    default:
      return 'Miembro';
  }
}

String _formatDate(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
