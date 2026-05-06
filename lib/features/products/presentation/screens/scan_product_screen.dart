import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/core/widgets/app_alert_dialog.dart';
import 'package:stockmind/core/widgets/remote_image_frame.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/dashboard_frame.dart';
import 'package:stockmind/features/locations/models/inventory_location.dart';
import 'package:stockmind/features/locations/providers/locations_provider.dart';
import 'package:stockmind/features/products/models/product.dart';
import 'package:stockmind/features/products/providers/products_provider.dart';

class ScanProductScreen extends StatefulWidget {
  const ScanProductScreen({super.key});

  @override
  State<ScanProductScreen> createState() => _ScanProductScreenState();
}

class _ScanProductScreenState extends State<ScanProductScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _handlingDetection = false;
  String? _lastCode;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return DashboardFrame(
      title: 'Escanear producto',
      subtitle:
          'Lee un QR o código de barras con la cámara para sumar o restar stock rápidamente.',
      child: Column(
        children: [
          if (!auth.canEdit)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No tienes permisos para realizar esta acción.'),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apunta la cámara al código del producto',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Soporta QR y códigos de barras. El escáner se pausará automáticamente al detectar un producto.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: MobileScanner(
                          controller: _controller,
                          onDetect: _handleDetect,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: () => _controller.start(),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Reanudar escáner'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => _controller.stop(),
                          icon: const Icon(Icons.pause_rounded),
                          label: const Text('Pausar'),
                        ),
                      ],
                    ),
                    if (_lastCode != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Último código leído: $_lastCode',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleDetect(BarcodeCapture capture) async {
    if (_handlingDetection) return;
    if (capture.barcodes.isEmpty) return;
    final rawValue = capture.barcodes.first.rawValue?.trim();
    if (rawValue == null || rawValue.isEmpty) return;

    _handlingDetection = true;
    _lastCode = rawValue;
    if (mounted) {
      setState(() {});
    }

    await _controller.stop();
    final provider = context.read<ProductsProvider>();
    final lookup = await provider.findProductByCode(rawValue);

    if (!mounted) return;

    if (lookup == null) {
      await showAppAlertDialog(
        context,
        type: AppAlertType.warning,
        title: 'Producto no encontrado',
        message:
            provider.error ?? 'No se encontró ningún producto con este código.',
      );
      _handlingDetection = false;
      await _controller.start();
      return;
    }

    final locations = context.read<LocationsProvider>().locations;
    await showDialog<void>(
      context: context,
      builder: (_) => _QuickAdjustDialog(
        product: lookup.product,
        locations: locations,
      ),
    );

    _handlingDetection = false;
    await _controller.start();
  }
}

class _QuickAdjustDialog extends StatefulWidget {
  const _QuickAdjustDialog({
    required this.product,
    required this.locations,
  });

  final Product product;
  final List<InventoryLocation> locations;

  @override
  State<_QuickAdjustDialog> createState() => _QuickAdjustDialogState();
}

class _QuickAdjustDialogState extends State<_QuickAdjustDialog> {
  final _quantityController = TextEditingController(text: '1');
  late String _selectedLocationId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedLocationId = _resolveInitialLocationId();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedLocation = _selectedLocation;

    return AlertDialog(
      title: const Text('Ajuste rápido de stock'),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                RemoteImageFrame(
                  size: 72,
                  imageUrl: widget.product.imageUrl,
                  icon: Icons.inventory_2_outlined,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.product.name, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        'Stock actual: ${widget.product.totalStock} unidades',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: _selectedLocationId,
              decoration: const InputDecoration(
                labelText: 'Ubicación',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              items: widget.locations
                  .map(
                    (location) => DropdownMenuItem<String>(
                      value: location.id,
                      child: Text(location.name),
                    ),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() => _selectedLocationId = value);
                    },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                prefixIcon: Icon(Icons.confirmation_number_outlined),
              ),
            ),
            const SizedBox(height: 12),
            if (selectedLocation != null)
              Text(
                'Stock en ubicación: ${widget.product.locationQuantities[selectedLocation.id]?.quantity ?? 0} unidades',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
        OutlinedButton.icon(
          onPressed: _saving ? null : () => _save(false),
          icon: const Icon(Icons.remove_rounded),
          label: const Text('- Restar stock'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : () => _save(true),
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_rounded),
          label: const Text('+ Sumar stock'),
        ),
      ],
    );
  }

  InventoryLocation? get _selectedLocation {
    for (final location in widget.locations) {
      if (location.id == _selectedLocationId) return location;
    }
    return null;
  }

  String _resolveInitialLocationId() {
    if (widget.product.locationQuantities.isNotEmpty) {
      return widget.product.locationQuantities.keys.first;
    }
    if (widget.locations.isNotEmpty) {
      return widget.locations.first.id;
    }
    return '';
  }

  Future<void> _save(bool increase) async {
    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity < 1) {
      await showAppAlertDialog(
        context,
        type: AppAlertType.warning,
        title: 'Cantidad inválida',
        message: 'La cantidad mínima permitida es 1.',
      );
      return;
    }

    if (!increase && quantity > widget.product.totalStock) {
      await showAppAlertDialog(
        context,
        type: AppAlertType.warning,
        title: 'Stock insuficiente',
        message:
            'No puedes descontar más unidades que el stock disponible.',
      );
      return;
    }

    final location = _selectedLocation;
    if (location == null) {
      await showAppAlertDialog(
        context,
        type: AppAlertType.warning,
        title: 'Ubicación requerida',
        message: 'Debes seleccionar una ubicación para ajustar el stock.',
      );
      return;
    }

    setState(() => _saving = true);
    final provider = context.read<ProductsProvider>();
    final success = await provider.adjustProductStock(
      productId: widget.product.id,
      locationId: location.id,
      locationName: location.name,
      quantity: quantity,
      increase: increase,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (!success) {
      await showAppAlertDialog(
        context,
        type: AppAlertType.error,
        title: 'No se pudo actualizar el stock',
        message:
            provider.error ?? 'No pudimos completar la operación.',
      );
      return;
    }

    await showAppAlertDialog(
      context,
      type: AppAlertType.success,
      title: increase ? 'Stock actualizado' : 'Stock descontado',
      message: increase
          ? 'Se sumaron $quantity unidades correctamente.'
          : 'Se descontaron $quantity unidades correctamente.',
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
