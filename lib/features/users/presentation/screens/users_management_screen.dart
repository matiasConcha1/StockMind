import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/app/routes.dart';
import 'package:stockmind/core/widgets/app_alert_dialog.dart';
import 'package:stockmind/core/widgets/empty_state.dart';
import 'package:stockmind/core/widgets/permission_guard.dart';
import 'package:stockmind/core/widgets/section_card.dart';
import 'package:stockmind/features/company/models/company_invitation.dart';
import 'package:stockmind/features/company/providers/current_company_provider.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/dashboard_frame.dart';
import 'package:stockmind/features/users/providers/user_provider.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _inviteEmailController = TextEditingController();
  String _inviteRole = 'viewer';

  @override
  void dispose() {
    _searchController.dispose();
    _inviteEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final companyProvider = context.watch<CurrentCompanyProvider>();
    final query = _searchController.text.trim().toLowerCase();

    return DashboardFrame(
      title: 'Miembros',
      subtitle:
          companyProvider.hasCompany
              ? 'Gestiona miembros, roles e invitaciones de ${companyProvider.companyName}.'
              : 'Debes pertenecer a una empresa para gestionar miembros.',
      onBackPressed: () => context.go(AppRoutePaths.dashboard),
      backLabel: 'Volver al centro de inventario',
      child: PermissionGuard(
        allowed: userProvider.canManageUsers && companyProvider.hasCompany,
        actionLabel: 'Volver al centro de inventario',
        onAction: () => context.go(AppRoutePaths.dashboard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionCard(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Buscar por nombre o correo',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 780;
                        final inviteFields = [
                          Expanded(
                            flex: 4,
                            child: TextField(
                              controller: _inviteEmailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Correo opcional',
                                prefixIcon: Icon(Icons.mail_outline_rounded),
                              ),
                            ),
                          ),
                          if (!compact) const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              initialValue: _inviteRole,
                              decoration: const InputDecoration(
                                labelText: 'Rol inicial',
                                prefixIcon: Icon(Icons.verified_user_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'editor',
                                  child: Text('Editor'),
                                ),
                                DropdownMenuItem(
                                  value: 'operator',
                                  child: Text('Operador'),
                                ),
                                DropdownMenuItem(
                                  value: 'viewer',
                                  child: Text('Visualizador'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _inviteRole = value);
                              },
                            ),
                          ),
                          if (!compact) const SizedBox(width: 12),
                          Expanded(
                            flex: compact ? 0 : 2,
                            child: FilledButton.icon(
                              onPressed: () => _inviteUser(
                                context,
                                requireEmail: true,
                              ),
                              icon: const Icon(Icons.person_add_alt_1_rounded),
                              label: const Text('Invitar correo'),
                            ),
                          ),
                          if (!compact) const SizedBox(width: 12),
                          Expanded(
                            flex: compact ? 0 : 2,
                            child: OutlinedButton.icon(
                              onPressed: () => _inviteUser(
                                context,
                                requireEmail: false,
                              ),
                              icon: const Icon(Icons.link_rounded),
                              label: const Text('Generar link'),
                            ),
                          ),
                        ];

                        if (compact) {
                          return Column(
                            children: [
                              inviteFields[0],
                              const SizedBox(height: 12),
                              inviteFields[2],
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _inviteUser(
                                    context,
                                    requireEmail: false,
                                  ),
                                  icon: const Icon(Icons.link_rounded),
                                  label: const Text('Generar link de acceso'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: () => _inviteUser(
                                    context,
                                    requireEmail: true,
                                  ),
                                  icon: const Icon(
                                    Icons.person_add_alt_1_rounded,
                                  ),
                                  label: const Text('Invitar por correo'),
                                ),
                              ),
                            ],
                          );
                        }

                        return Row(children: inviteFields);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Miembros activos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: userProvider.watchUsers(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const SectionCard(
                    child: SizedBox(
                      height: 220,
                      child: EmptyState(
                        title: 'No se pudieron cargar los miembros',
                        subtitle:
                            'Revisa tu conexión o los permisos de Firestore.',
                        icon: Icons.group_off_outlined,
                        compact: true,
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const SectionCard(
                    child: SizedBox(
                      height: 220,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                final members = snapshot.data!.docs.where((doc) {
                  final data = doc.data();
                  final name = ((data['displayName'] ?? '') as String)
                      .toLowerCase();
                  final email = ((data['email'] ?? '') as String).toLowerCase();
                  return query.isEmpty ||
                      name.contains(query) ||
                      email.contains(query);
                }).toList();
                if (members.isEmpty) {
                  return const SectionCard(
                    child: SizedBox(
                      height: 220,
                      child: EmptyState(
                        title: 'Sin miembros visibles',
                        subtitle:
                            'Cuando invites personas o ajustes la búsqueda, aparecerán aquí.',
                        icon: Icons.groups_2_outlined,
                        compact: true,
                      ),
                    ),
                  );
                }
                return Column(
                  children: members
                      .map(
                        (doc) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _MemberCard(doc: doc),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Invitaciones',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: userProvider.watchInvitations(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const SectionCard(
                    child: SizedBox(
                      height: 220,
                      child: EmptyState(
                        title: 'No se pudieron cargar las invitaciones',
                        subtitle: 'Revisa permisos o vuelve a intentarlo.',
                        icon: Icons.mark_email_unread_outlined,
                        compact: true,
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const SectionCard(
                    child: SizedBox(
                      height: 180,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                final invites = snapshot.data!.docs;
                if (invites.isEmpty) {
                  return const SectionCard(
                    child: SizedBox(
                      height: 180,
                      child: EmptyState(
                        title: 'Sin invitaciones registradas',
                        subtitle:
                            'Las invitaciones pendientes, aceptadas o revocadas aparecerán aquí.',
                        icon: Icons.mail_outline_rounded,
                        compact: true,
                      ),
                    ),
                  );
                }
                return Column(
                  children: invites
                      .map(
                        (doc) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _InvitationCard(doc: doc),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _inviteUser(
    BuildContext context, {
    required bool requireEmail,
  }) async {
    final provider = context.read<UserProvider>();
    final email = _inviteEmailController.text.trim();
    if (requireEmail && email.isEmpty) {
      await showAppAlertDialog(
        context,
        type: AppAlertType.warning,
        title: 'Falta el correo del invitado',
        message:
            'Ingresa un email si quieres enviar una invitación dirigida a una persona concreta.',
      );
      return;
    }
    try {
      final invitation = await provider.inviteUser(
        email: email.isEmpty ? null : email,
        role: _inviteRole,
      );
      _inviteEmailController.clear();
      if (!context.mounted) return;
      final invitationLink = provider.buildInvitationLink(invitation);
      if (!requireEmail) {
        await Clipboard.setData(ClipboardData(text: invitationLink));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link de invitación copiado al portapapeles.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La invitación por correo quedó registrada.'),
          ),
        );
      }
      await showAppAlertDialog(
        context,
        type: AppAlertType.success,
        title: requireEmail ? 'Invitación enviada' : 'Link generado',
        message: requireEmail
            ? 'La invitación quedó registrada y también puede compartirse como link seguro.'
            : 'El link quedó listo y fue copiado para compartirlo con tu equipo.',
      );
    } on FirebaseException catch (error) {
      if (!context.mounted) return;
      await showAppAlertDialog(
        context,
        type: AppAlertType.error,
        title: 'No se pudo enviar la invitación',
        message: error.message ?? 'Ocurrió un error inesperado.',
      );
    }
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.doc});

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final userProvider = context.read<UserProvider>();
    final data = doc.data();
    final name = ((data['displayName'] ?? 'Usuario') as String).trim();
    final email = ((data['email'] ?? '') as String).trim();
    final role = ((data['role'] ?? 'viewer') as String).trim().toLowerCase();
    final status = ((data['status'] ?? 'accepted') as String).trim();
    final joinedAt = _formatDate(data['joinedAt']);
    final isActive = (data['isActive'] ?? true) == true;
    final isSelf = userProvider.currentUser?.id == doc.id;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(email),
                  ],
                ),
              ),
              _StatusPill(
                label: isActive ? 'Activo' : 'Inactivo',
                color: isActive ? Colors.green : Theme.of(context).colorScheme.error,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetaPill(icon: Icons.verified_user_outlined, label: _roleLabel(role)),
              _MetaPill(icon: Icons.event_outlined, label: 'Ingreso: $joinedAt'),
              _MetaPill(icon: Icons.info_outline_rounded, label: status),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    prefixIcon: Icon(Icons.shield_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                    DropdownMenuItem(value: 'editor', child: Text('Editor')),
                    DropdownMenuItem(value: 'operator', child: Text('Operador')),
                    DropdownMenuItem(value: 'viewer', child: Text('Visualizador')),
                  ],
                  onChanged: isSelf
                      ? null
                      : (value) async {
                          if (value == null || value == role) return;
                          await userProvider.updateUserRole(
                            userId: doc.id,
                            role: value,
                          );
                        },
                ),
              ),
              if (!isSelf)
                OutlinedButton.icon(
                  onPressed: () => _removeMember(context, userProvider, doc.id),
                  icon: const Icon(Icons.person_remove_outlined),
                  label: const Text('Remover'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _removeMember(
    BuildContext context,
    UserProvider provider,
    String userId,
  ) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: '¿Remover miembro?',
      message: 'El usuario perderá acceso a esta empresa.',
      confirmLabel: 'Remover',
      cancelLabel: 'Cancelar',
    );
    if (!confirmed || !context.mounted) return;
    try {
      await provider.removeMember(userId);
      if (!context.mounted) return;
      await showAppAlertDialog(
        context,
        type: AppAlertType.success,
        title: 'Miembro removido',
        message: 'El usuario fue removido de la empresa activa.',
      );
    } on FirebaseException catch (error) {
      if (!context.mounted) return;
      await showAppAlertDialog(
        context,
        type: AppAlertType.error,
        title: 'No se pudo remover',
        message: error.message ?? 'No fue posible completar la operación.',
      );
    }
  }
}

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({required this.doc});

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<UserProvider>();
    final invitation = CompanyInvitation.fromFirestore(doc);
    final email = invitation.email.trim();
    final role = invitation.role.trim().toLowerCase();
    final status = invitation.status.trim().toLowerCase();
    final createdAt = _formatDate(invitation.createdAt);
    final expiresAt = invitation.expiresAt == null
        ? 'Sin expiración'
        : _formatDate(invitation.expiresAt);

    return SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email.isEmpty ? 'Invitación por link' : email,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetaPill(
                      icon: Icons.verified_user_outlined,
                      label: _roleLabel(role),
                    ),
                    _MetaPill(
                      icon: Icons.schedule_rounded,
                      label: 'Enviada: $createdAt',
                    ),
                    _MetaPill(
                      icon: Icons.timelapse_rounded,
                      label: 'Expira: $expiresAt',
                    ),
                    _StatusPill(
                      label: _statusLabel(status),
                      color: _statusColor(context, status),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (invitation.inviteToken.trim().isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _copyLink(context, provider, invitation),
                  icon: const Icon(Icons.copy_all_rounded),
                  label: const Text('Copiar link'),
                ),
              if (status == 'pending')
                OutlinedButton.icon(
                  onPressed: () => _revoke(context, provider, doc.id),
                  icon: const Icon(Icons.block_outlined),
                  label: const Text('Revocar'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _copyLink(
    BuildContext context,
    UserProvider provider,
    CompanyInvitation invitation,
  ) async {
    await Clipboard.setData(
      ClipboardData(text: provider.buildInvitationLink(invitation)),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link de invitación copiado al portapapeles.'),
      ),
    );
  }

  Future<void> _revoke(
    BuildContext context,
    UserProvider provider,
    String invitationId,
  ) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: '¿Revocar invitación?',
      message: 'La invitación dejará de estar disponible para el usuario.',
      confirmLabel: 'Revocar',
      cancelLabel: 'Cancelar',
    );
    if (!confirmed || !context.mounted) return;
    try {
      await provider.revokeInvitation(invitationId);
      if (!context.mounted) return;
      await showAppAlertDialog(
        context,
        type: AppAlertType.success,
        title: 'Invitación revocada',
        message: 'La invitación fue revocada correctamente.',
      );
    } on FirebaseException catch (error) {
      if (!context.mounted) return;
      await showAppAlertDialog(
        context,
        type: AppAlertType.error,
        title: 'No se pudo revocar',
        message: error.message ?? 'No fue posible revocar la invitación.',
      );
    }
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

String _formatDate(dynamic value) {
  DateTime? date;
  if (value is Timestamp) date = value.toDate();
  if (value is DateTime) date = value;
  if (date == null) return 'Sin registro';
  return DateFormat('dd/MM/yyyy HH:mm').format(date);
}

String _roleLabel(String role) {
  switch (role) {
    case 'admin':
      return 'Administrador';
    case 'editor':
      return 'Editor';
    case 'operator':
      return 'Operador';
    case 'viewer':
      return 'Visualizador';
    default:
      return 'Usuario';
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'pending':
      return 'Pendiente';
    case 'accepted':
      return 'Aceptada';
    case 'revoked':
      return 'Revocada';
    default:
      return status;
  }
}

Color _statusColor(BuildContext context, String status) {
  switch (status) {
    case 'pending':
      return Colors.amber.shade700;
    case 'accepted':
      return Colors.green;
    case 'revoked':
      return Theme.of(context).colorScheme.error;
    default:
      return Theme.of(context).colorScheme.primary;
  }
}
