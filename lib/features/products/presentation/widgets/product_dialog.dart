import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/features/locations/models/inventory_location.dart';
import 'package:stockmind/features/locations/presentation/widgets/location_dialog.dart';
import 'package:stockmind/features/locations/providers/locations_provider.dart';
import 'package:stockmind/features/products/models/product.dart';

class ProductDialogResult {
  const ProductDialogResult({
    required this.product,
    this.stockChangeReason,
  });

  final Product product;
  final String? stockChangeReason;
}

class ProductDialog extends StatefulWidget {
  const ProductDialog({
    this.product,
    super.key,
  });

  final Product? product;

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _priceController;
  late final TextEditingController _minStockController;
  late final TextEditingController _reasonController;
  final Map<String, TextEditingController> _locationControllers = {};

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _categoryController = TextEditingController(text: product?.category ?? '');
    _priceController = TextEditingController(
      text: product?.price.toString() ?? '',
    );
    _minStockController = TextEditingController(
      text: product?.minStock.toString() ?? '',
    );
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _minStockController.dispose();
    _reasonController.dispose();
    for (final controller in _locationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationsProvider = context.watch<LocationsProvider>();
    final locations = locationsProvider.locations;
    _syncLocationControllers(locations);

    final distributedTotal = _computeDistributedTotal();
    final hasLocations = locations.isNotEmpty;
    final inheritedUnassignedStock = widget.product != null &&
            !widget.product!.hasLocationAssignments &&
            widget.product!.totalStock > 0
        ? widget.product!.totalStock
        : 0;

    return AlertDialog(
      title: Text(widget.product == null ? 'Nuevo producto' : 'Editar producto'),
      content: SizedBox(
        width: 640,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.76,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Ingresa un nombre.'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Ingresa una categoría.'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(labelText: 'Precio'),
                          validator: (value) {
                            final parsed = double.tryParse(value ?? '');
                            if (parsed == null) return 'Precio inválido.';
                            if (parsed < 0) {
                              return 'El precio debe ser mayor o igual a 0.';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextFormField(
                          controller: _minStockController,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Stock mínimo'),
                          validator: (value) {
                            final parsed = int.tryParse(value ?? '');
                            if (parsed == null) return 'Valor inválido.';
                            if (parsed < 0) {
                              return 'El stock mínimo debe ser mayor o igual a 0.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Distribución por ubicación',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: locationsProvider.isLoading
                            ? null
                            : () => _openCreateLocationDialog(context),
                        icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                        label: const Text('Crear ubicación'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!hasLocations)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.48),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Primero crea una ubicación para repartir el stock.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonalIcon(
                            onPressed: () => _openCreateLocationDialog(context),
                            icon: const Icon(Icons.place_rounded),
                            label: const Text('Crear ubicación'),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    if (inheritedUnassignedStock > 0) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Este producto tiene stock heredado sin ubicar: $inheritedUnassignedStock unidades. Asigna cantidades para distribuirlo correctamente.',
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    ...locations.map((location) {
                      final controller = _locationControllers[location.id]!;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: location.name,
                            helperText: _locationHelper(location),
                            prefixIcon: Icon(_iconForType(location.type)),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }
                            final parsed = int.tryParse(value);
                            if (parsed == null) {
                              return 'Cantidad inválida.';
                            }
                            if (parsed < 0) {
                              return 'La cantidad debe ser mayor o igual a 0.';
                            }
                            return null;
                          },
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 10),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Stock total',
                    ),
                    child: Text(
                      '$distributedTotal unidades',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (hasLocations) ...[
                    const SizedBox(height: 10),
                    Text(
                      'El stock total se calcula automáticamente con la suma de todas las ubicaciones.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (widget.product != null) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Motivo del ajuste',
                        hintText: 'Ej. reposición, traslado o corrección manual',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: hasLocations ? () => _submit(locations) : null,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _openCreateLocationDialog(BuildContext context) async {
    final result = await showDialog<InventoryLocation>(
      context: context,
      builder: (_) => const LocationDialog(),
    );

    if (result == null || !context.mounted) return;
    await context.read<LocationsProvider>().createLocation(result);
    if (mounted) setState(() {});
  }

  void _syncLocationControllers(List<InventoryLocation> locations) {
    for (final location in locations) {
      _locationControllers.putIfAbsent(
        location.id,
        () => TextEditingController(
          text: widget.product?.locationQuantities[location.id]?.quantity
                  .toString() ??
              '',
        ),
      );
    }
  }

  int _computeDistributedTotal() {
    return _locationControllers.values.fold<int>(0, (sum, controller) {
      final parsed = int.tryParse(controller.text.trim()) ?? 0;
      return sum + (parsed < 0 ? 0 : parsed);
    });
  }

  void _submit(List<InventoryLocation> locations) {
    if (!_formKey.currentState!.validate()) return;

    final locationQuantities = <String, ProductLocationQuantity>{};
    for (final location in locations) {
      final quantity =
          int.tryParse(_locationControllers[location.id]?.text.trim() ?? '') ?? 0;
      if (quantity > 0) {
        locationQuantities[location.id] = ProductLocationQuantity(
          locationId: location.id,
          locationName: location.name,
          quantity: quantity,
        );
      }
    }

    if (locationQuantities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe existir al menos una ubicación con cantidad mayor a 0.'),
        ),
      );
      return;
    }

    final totalStock = locationQuantities.values.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    final minStock = int.parse(_minStockController.text.trim());
    final now = DateTime.now();

    final product = Product(
      id: widget.product?.id ?? '',
      name: _nameController.text.trim(),
      category: _categoryController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      totalStock: totalStock,
      minStock: minStock,
      status: totalStock == 0
          ? 'critical'
          : totalStock <= minStock
              ? 'low'
              : 'ok',
      locationQuantities: locationQuantities,
      createdAt: widget.product?.createdAt ?? now,
      updatedAt: now,
    );

    Navigator.of(context).pop(
      ProductDialogResult(
        product: product,
        stockChangeReason: _reasonController.text.trim(),
      ),
    );
  }

  String _locationHelper(InventoryLocation location) {
    final description = location.description.trim();
    if (description.isEmpty) return location.type;
    return '${location.type} · $description';
  }

  IconData _iconForType(String type) {
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
}
