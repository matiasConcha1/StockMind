import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/app/routes.dart';
import 'package:stockmind/core/widgets/app_alert_dialog.dart';
import 'package:stockmind/core/widgets/empty_state.dart';
import 'package:stockmind/core/widgets/remote_image_frame.dart';
import 'package:stockmind/core/widgets/section_card.dart';
import 'package:stockmind/core/widgets/stockmind_loading_screen.dart';
import 'package:stockmind/features/company/providers/current_company_provider.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/dashboard_frame.dart';
import 'package:stockmind/features/locations/models/inventory_location.dart';
import 'package:stockmind/features/locations/presentation/widgets/location_detail_dialog.dart';
import 'package:stockmind/features/locations/presentation/widgets/location_dialog.dart';
import 'package:stockmind/features/locations/providers/locations_provider.dart';

class LocationsScreen extends StatelessWidget {
  const LocationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LocationsProvider>();
    final company = context.watch<CurrentCompanyProvider>();
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width < 760 ? 1 : width < 1180 ? 2 : 3;
    final hasActiveCompany =
        company.hasAcceptedMembership && company.companyId != null;
    final canManageLocations = company.canManageLocations;
    final canDeleteLocations = company.canDelete;

    return DashboardFrame(
      title: 'Ubicaciones',
      subtitle:
          'Gestiona espacios físicos como refrigeradores, congeladoras, cajas y closets.',
      actions: [
        if (!hasActiveCompany)
          FilledButton.icon(
            onPressed: () => context.go(AppRoutePaths.company),
            icon: const Icon(Icons.add_business_outlined),
            label: const Text('Crear espacio'),
          ),
        FilledButton.icon(
          onPressed:
              provider.isLoading || !hasActiveCompany || !canManageLocations
                  ? null
                  : () => _openDialog(context),
          icon: const Icon(Icons.add_location_alt_outlined),
          label: const Text('Nueva ubicación'),
        ),
      ],
      child: Column(
        children: [
          if (!hasActiveCompany)
            SectionCard(
              child: SizedBox(
                height: 320,
                child: EmptyState(
                  title: 'Configura tu espacio de trabajo para comenzar',
                  subtitle:
                      'Crea o selecciona un espacio para organizar ubicaciones, stock real y operaciones del inventario.',
                  icon: Icons.business_outlined,
                  actionLabel: 'Crear espacio',
                  onAction: () => context.go(AppRoutePaths.company),
                  compact: true,
                ),
              ),
            )
          else ...[
            if (provider.error != null) ...[
              _LocationsErrorBanner(message: provider.error!),
              const SizedBox(height: 16),
            ],
            if (provider.isLoading && !provider.hasLocations)
              const SectionCard(
                child: SizedBox(
                  height: 320,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: StockMindLoadingPanel(
                        compact: true,
                        statusMessage: 'Cargando ubicaciones...',
                      ),
                    ),
                  ),
                ),
              )
            else if (!provider.isLoading && !provider.hasLocations)
              SectionCard(
                child: SizedBox(
                  height: 320,
                  child: EmptyState(
                    title: 'Sin ubicaciones todavía',
                    subtitle:
                        'Crea espacios físicos para distribuir productos y controlar stock real por ubicación.',
                    icon: Icons.place_outlined,
                    actionLabel:
                        canManageLocations ? 'Crear ubicación' : null,
                    onAction:
                        canManageLocations ? () => _openDialog(context) : null,
                    compact: true,
                  ),
                ),
              )
            else
              GridView.builder(
                itemCount: provider.locations.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: width < 760 ? 1.28 : 1.06,
                ),
                itemBuilder: (context, index) {
                  final location = provider.locations[index];
                  final productCount =
                      provider.productCountForLocation(location.id);
                  final totalUnits = provider.totalUnitsForLocation(location.id);
                  return _LocationCard(
                    location: location,
                    productCount: productCount,
                    totalUnits: totalUnits,
                    canEdit: canManageLocations,
                    canDelete: canDeleteLocations,
                    onOpen: () => _openDetail(context, location),
                    onEdit: () => _openDialog(context, location: location),
                    onDelete: () => _confirmDelete(context, location),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _openDialog(
    BuildContext context, {
    InventoryLocation? location,
  }) async {
    final result = await showDialog<LocationDialogResult>(
      context: context,
      builder: (_) => LocationDialog(location: location),
    );
    if (result == null || !context.mounted) return;

    final provider = context.read<LocationsProvider>();
    if (location == null) {
      await provider.createLocation(
        result.location,
        imageFile: result.imageFile,
      );
      if (!context.mounted) return;
      await showAppAlertDialog(
        context,
        type: provider.error == null ? AppAlertType.success : AppAlertType.error,
        title:
            provider.error == null ? 'Ubicación creada' : 'No se pudo crear la ubicación',
        message: provider.error == null
            ? 'La ubicación fue creada correctamente.'
            : provider.error!,
      );
      return;
    }

    await provider.updateLocation(
      result.location,
      imageFile: result.imageFile,
      removeImage: result.removeImage,
    );
    if (!context.mounted) return;
    await showAppAlertDialog(
      context,
      type: provider.error == null ? AppAlertType.success : AppAlertType.error,
      title: provider.error == null
          ? 'Ubicación actualizada'
          : 'No se pudo actualizar la ubicación',
      message: provider.error == null
          ? 'Los cambios fueron guardados correctamente.'
          : provider.error!,
    );
  }

  Future<void> _openDetail(
    BuildContext context,
    InventoryLocation location,
  ) async {
    final snapshot = context.read<LocationsProvider>().buildSnapshot(location);
    await showDialog<void>(
      context: context,
      builder: (_) => LocationDetailDialog(snapshot: snapshot),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    InventoryLocation location,
  ) async {
    final shouldDelete = await showAppConfirmDialog(
      context,
      title: '¿Eliminar ubicación?',
      message:
          'Esta acción eliminará la ubicación del sistema. Si aún tiene productos asignados, la operación será bloqueada.',
      confirmLabel: 'Eliminar',
      cancelLabel: 'Cancelar',
    );

    if (!shouldDelete || !context.mounted) return;
    final provider = context.read<LocationsProvider>();
    final success = await provider.deleteLocation(location.id);
    if (!context.mounted) return;
    await showAppAlertDialog(
      context,
      type: success ? AppAlertType.success : AppAlertType.error,
      title: success ? 'Ubicación eliminada' : 'No se pudo eliminar',
      message: success
          ? 'La ubicación fue eliminada correctamente.'
          : (provider.error ??
              'No pudimos completar la operación. Inténtalo nuevamente.'),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.location,
    required this.productCount,
    required this.totalUnits,
    required this.canEdit,
    required this.canDelete,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final InventoryLocation location;
  final int productCount;
  final int totalUnits;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SectionCard(
      interactive: true,
      onTap: onOpen,
      borderRadius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RemoteImageFrame(
                size: 64,
                imageUrl: location.imageUrl,
                icon: _iconForType(location.type),
                borderRadius: BorderRadius.circular(18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(location.name, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _capitalize(location.type),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (canEdit || canDelete)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    if (canEdit)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Editar'),
                      ),
                    if (canDelete)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Eliminar'),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            location.description.isEmpty
                ? 'Sin descripción adicional.'
                : location.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
          const Spacer(),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Pill(label: '$productCount productos'),
              _Pill(label: '$totalUnits unidades'),
            ],
          ),
        ],
      ),
    );
  }

  static IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'refrigerador':
        return Icons.kitchen_outlined;
      case 'congeladora':
        return Icons.ac_unit_rounded;
      case 'caja':
        return Icons.inventory_2_outlined;
      case 'closet':
        return Icons.door_sliding_outlined;
      default:
        return Icons.place_outlined;
    }
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label),
    );
  }
}

class _LocationsErrorBanner extends StatelessWidget {
  const _LocationsErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
