import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/app/routes.dart';
import 'package:stockmind/core/widgets/app_alert_dialog.dart';
import 'package:stockmind/core/widgets/empty_state.dart';
import 'package:stockmind/core/widgets/permission_guard.dart';
import 'package:stockmind/core/widgets/section_card.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/dashboard_frame.dart';
import 'package:stockmind/features/users/providers/user_provider.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final query = _searchController.text.trim().toLowerCase();

    return DashboardFrame(
      title: 'Usuarios',
      subtitle: 'Gestiona usuarios, roles y el estado operativo del sistema.',
      onBackPressed: () => context.go(AppRoutePaths.dashboard),
      backLabel: 'Volver al centro de inventario',
      child: PermissionGuard(
        allowed: userProvider.canManageUsers,
        actionLabel: 'Volver al centro de inventario',
        onAction: () => context.go(AppRoutePaths.dashboard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionCard(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Buscar por nombre o correo',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: userProvider.watchUsers(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint(
                    'UsersManagementScreen.watchUsers error: ${snapshot.error}',
                  );
                  return const SectionCard(
                    child: SizedBox(
                      height: 240,
                      child: EmptyState(
                        title: 'No se pudieron cargar los usuarios',
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
                      height: 240,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                final users = snapshot.data!.docs.where((doc) {
                  final data = doc.data();
                  final name = ((data['name'] ?? '') as String).toLowerCase();
                  final email = ((data['email'] ?? '') as String).toLowerCase();
                  return query.isEmpty ||
                      name.contains(query) ||
                      email.contains(query);
                }).toList();

                if (users.isEmpty) {
                  return const SectionCard(
                    child: SizedBox(
                      height: 240,
                      child: EmptyState(
                        title: 'No hay usuarios registrados',
                        subtitle:
                            'Ajusta la búsqueda para encontrar usuarios registrados.',
                        icon: Icons.manage_accounts_outlined,
                        compact: true,
                      ),
                    ),
                  );
                }

                return Column(
                  children: users
                      .map(
                        (doc) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _UserCard(doc: doc),
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
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.doc});

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final userProvider = context.read<UserProvider>();
    final data = doc.data();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name = ((data['name'] ?? 'Usuario') as String).trim();
    final email = ((data['email'] ?? '') as String).trim();
    final role = _normalizeRole(data['role']);
    final isActive = (data['isActive'] ?? true) == true;
    final createdAt = _formatDate(data['createdAt']);
    final lastLoginAt = _formatDate(data['lastLoginAt']);
    final isSelf = userProvider.currentUser?.id == doc.id;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                child: Text(
                  _initials(name),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: (isActive ? Colors.green : colorScheme.error)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isActive ? 'Activo' : 'Inactivo',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isActive ? Colors.green : colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _pill(context, Icons.admin_panel_settings_outlined,
                  _roleLabel(role)),
              _pill(context, Icons.calendar_today_outlined, 'Creado: $createdAt'),
              _pill(context, Icons.login_rounded, 'Último acceso: $lastLoginAt'),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 720;
              final controls = [
                SizedBox(
                  width: compact ? double.infinity : 220,
                  child: DropdownButtonFormField<String>(
                    initialValue: role,
                    decoration: const InputDecoration(
                      labelText: 'Rol',
                      prefixIcon: Icon(Icons.verified_user_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text('Administrador'),
                      ),
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
                    onChanged: isSelf
                        ? null
                        : (value) async {
                            if (value == null || value == role) return;
                            await _updateRole(
                              context,
                              userProvider: userProvider,
                              userId: doc.id,
                              role: value,
                            );
                          },
                  ),
                ),
                SizedBox(
                  width: compact ? double.infinity : 220,
                  child: SwitchListTile.adaptive(
                    value: isActive,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Usuario activo'),
                    subtitle: Text(
                      isSelf
                          ? 'No puedes desactivarte a ti mismo.'
                          : 'Controla si puede seguir operando en StockMind.',
                    ),
                    onChanged: isSelf
                        ? null
                        : (value) async {
                            await _updateActive(
                              context,
                              userProvider: userProvider,
                              userId: doc.id,
                              isActive: value,
                            );
                          },
                  ),
                ),
              ];

              return compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: controls
                          .expand((item) => [item, const SizedBox(height: 12)])
                          .toList()
                        ..removeLast(),
                    )
                  : Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: controls,
                    );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _updateRole(
    BuildContext context, {
    required UserProvider userProvider,
    required String userId,
    required String role,
  }) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: '¿Cambiar rol de usuario?',
      message: 'Esta acción actualizará los permisos del usuario en StockMind.',
      confirmLabel: 'Cambiar rol',
      cancelLabel: 'Cancelar',
    );
    if (!confirmed || !context.mounted) return;
    try {
      await userProvider.updateUserRole(userId: userId, role: role);
      if (!context.mounted) return;
      await showAppAlertDialog(
        context,
        type: AppAlertType.success,
        title: 'Rol actualizado',
        message: 'Los permisos del usuario fueron actualizados correctamente.',
      );
    } on FirebaseException catch (error) {
      if (!context.mounted) return;
      await showAppAlertDialog(
        context,
        type: AppAlertType.error,
        title: 'No se pudo cambiar el rol',
        message: error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Solo un administrador puede actualizar roles.',
      );
    }
  }

  Future<void> _updateActive(
    BuildContext context, {
    required UserProvider userProvider,
    required String userId,
    required bool isActive,
  }) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: isActive ? '¿Activar usuario?' : '¿Desactivar usuario?',
      message: isActive
          ? 'El usuario volverá a operar en StockMind.'
          : 'El usuario dejará de poder acceder a StockMind.',
      confirmLabel: isActive ? 'Activar' : 'Desactivar',
      cancelLabel: 'Cancelar',
    );
    if (!confirmed || !context.mounted) return;
    try {
      await userProvider.setUserActive(userId: userId, isActive: isActive);
      if (!context.mounted) return;
      await showAppAlertDialog(
        context,
        type: AppAlertType.success,
        title: isActive ? 'Usuario activado' : 'Usuario desactivado',
        message: isActive
            ? 'El usuario fue activado correctamente.'
            : 'El usuario fue desactivado correctamente.',
      );
    } on FirebaseException catch (error) {
      if (!context.mounted) return;
      await showAppAlertDialog(
        context,
        type: AppAlertType.error,
        title: 'No se pudo actualizar el estado',
        message: error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Solo un administrador puede cambiar este estado.',
      );
    }
  }

  Widget _pill(BuildContext context, IconData icon, String label) {
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

  static String _normalizeRole(dynamic value) {
    final role = (value is String ? value : '').trim().toLowerCase();
    switch (role) {
      case 'admin':
      case 'editor':
      case 'operator':
      case 'viewer':
        return role;
      default:
        return 'viewer';
    }
  }

  static String _roleLabel(String role) {
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

  static String _formatDate(dynamic value) {
    DateTime? date;
    if (value is Timestamp) date = value.toDate();
    if (value is DateTime) date = value;
    if (date == null) return 'Sin registro';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  static String _initials(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return '?';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}'
        .toUpperCase();
  }
}
