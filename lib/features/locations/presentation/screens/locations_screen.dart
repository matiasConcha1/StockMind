import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/core/widgets/empty_state.dart';
import 'package:stockmind/core/widgets/remote_image_frame.dart';
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
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width < 760 ? 1 : width < 1180 ? 2 : 3;

    return DashboardFrame(
      title: 'Ubicaciones',
      subtitle:
          'Gestiona espacios físicos como refrigeradores, congeladoras, cajas y closets.',
      actions: [
        FilledButton.icon(
          onPressed: provider.isLoading ? null : () => _openDialog(context),
          icon: const Icon(Icons.add_location_alt_rounded),
          label: const Text('Nueva ubicación'),
        ),
      ],
      child: Column(
        children: [
          if (provider.error != null) ...[
            _LocationsErrorBanner(message: provider.error!),
            const SizedBox(height: 16),
          ],
          if (provider.isLoading && !provider.hasLocations)
            const Card(
              child: SizedBox(
                height: 320,
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (!provider.isLoading && !provider.hasLocations)
            const Card(
              child: SizedBox(
                height: 320,
                child: EmptyState(
                  title: 'Sin ubicaciones todavía',
                  subtitle:
                      'Crea espacios físicos para distribuir productos y controlar stock real por ubicación.',
                  icon: Icons.place_outlined,
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
                final productCount = provider.productCountForLocation(location.id);
                final totalUnits = provider.totalUnitsForLocation(location.id);
                return _LocationCard(
                  location: location,
                  productCount: productCount,
                  totalUnits: totalUnits,
                  onOpen: () => _openDetail(context, location),
                  onEdit: () => _openDialog(context, location: location),
                  onDelete: () => _confirmDelete(context, location),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _openDialog(
    BuildContext context, {
    InventoryLocation? location,
  }) async {
    final result = await showDialog<InventoryLocation>(
      context: context,
      builder: (_) => LocationDialog(location: location),
    );
    if (result == null || !context.mounted) return;

    final provider = context.read<LocationsProvider>();
    if (location == null) {
      await provider.createLocation(result);
    } else {
      await provider.updateLocation(result);
    }
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
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar ubicación'),
        content: Text('¿Deseas eliminar "${location.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && context.mounted) {
      await context.read<LocationsProvider>().deleteLocation(location.id);
    }
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.location,
    required this.productCount,
    required this.totalUnits,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final InventoryLocation location;
  final int productCount;
  final int totalUnits;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Eliminar')),
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
        ),
      ),
    );
  }

  static IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'refrigerador':
        return Icons.kitchen_rounded;
      case 'congeladora':
        return Icons.ac_unit_rounded;
      case 'caja':
        return Icons.inventory_rounded;
      case 'closet':
        return Icons.checkroom_rounded;
      default:
        return Icons.place_rounded;
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
      ),
    );
  }
}
