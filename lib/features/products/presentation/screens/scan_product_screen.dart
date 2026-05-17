import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/app/routes.dart';
import 'package:stockmind/core/widgets/app_alert_dialog.dart';
import 'package:stockmind/core/widgets/remote_image_frame.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/dashboard_frame.dart';
import 'package:stockmind/features/locations/models/inventory_location.dart';
import 'package:stockmind/features/locations/providers/locations_provider.dart';
import 'package:stockmind/features/products/models/product.dart';
import 'package:stockmind/features/products/presentation/widgets/product_dialog.dart';
import 'package:stockmind/features/products/providers/products_provider.dart';
import 'package:stockmind/features/replenishment/presentation/widgets/stock_request_dialog.dart';

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
  bool _searching = false;
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
      onBackPressed: () => context.go(AppRoutePaths.products),
      backLabel: 'Volver',
      subtitle:
          'Lee un QR o código de barras con la cámara para reconocer productos y ajustar stock rápidamente.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!auth.canManageInventory)
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
                      'Soporta QR y códigos de barras. El escáner se pausa al detectar un código para evitar lecturas repetidas.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            MobileScanner(
                              controller: _controller,
                              onDetect: _handleDetect,
                            ),
                            if (_searching)
                              Container(
                                color: Colors.black.withValues(alpha: 0.32),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          ],
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
    _searching = true;
    _lastCode = rawValue;
    if (mounted) {
      setState(() {});
    }

    await _controller.stop();
    final provider = context.read<ProductsProvider>();
    final lookup = await provider.findProductByCode(rawValue);

    if (!mounted) return;
    _searching = false;
    setState(() {});

    if (lookup == null) {
      final createProduct = await showAppAlertDialog(
        context,
        type: AppAlertType.confirm,
        title: 'Producto no encontrado',
        message: provider.error ??
            'No se encontró ningún producto con este código. Puedes crear uno nuevo usando este valor.',
        confirmLabel: 'Crear producto',
        cancelLabel: 'Cerrar',
        barrierDismissible: false,
      );
      if (createProduct == true && mounted) {
        await _openCreateProductWithCode(rawValue);
      }
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

  Future<void> _openCreateProductWithCode(String code) async {
    final result = await showDialog<ProductDialogResult>(
      context: context,
      builder: (_) => ProductDialog(initialBarcode: code),
    );

    if (result == null || !mounted) return;
    final provider = context.read<ProductsProvider>();
    await provider.createProduct(
      result.product,
      imageFile: result.imageFile,
    );
    if (!mounted) return;
    await showAppAlertDialog(
      context,
      type: provider.error == null ? AppAlertType.success : AppAlertType.error,
      title: provider.error == null
          ? 'Producto creado'
          : 'No se pudo crear el producto',
      message: provider.error == null
          ? 'El producto fue agregado correctamente al inventario.'
          : provider.error!,
    );
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
  late String _targetLocationId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedLocationId = _resolveInitialLocationId();
    _targetLocationId = _resolveTargetLocationId();
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
    final targetLocation = _targetLocation;

    return AlertDialog(
      title: const Text('Producto reconocido'),
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
                        widget.product.category,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stock actual: ${widget.product.totalStock} unidades',
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (widget.product.expiryDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Vence: ${widget.product.expiryDate!.day.toString().padLeft(2, '0')}/${widget.product.expiryDate!.month.toString().padLeft(2, '0')}/${widget.product.expiryDate!.year}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: widget.product.isExpired
                                ? colorScheme.error
                                : colorScheme.onSurface.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (widget.product.locationsStock.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Stock por ubicación',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: widget.product.locationsStock
                    .map(
                      (item) => _stockPill(
                        context,
                        '${item.locationName} → ${item.quantity}',
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: _selectedLocationId.isEmpty ? null : _selectedLocationId,
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
            DropdownButtonFormField<String>(
              initialValue: _targetLocationId.isEmpty ? null : _targetLocationId,
              decoration: const InputDecoration(
                labelText: 'Ubicación destino',
                prefixIcon: Icon(Icons.compare_arrows_rounded),
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
                      setState(() => _targetLocationId = value);
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
            if (targetLocation != null) ...[
              const SizedBox(height: 6),
              Text(
                'Destino seleccionado: ${targetLocation.name}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
        OutlinedButton.icon(
          onPressed: _saving ? null : _adjustExact,
          icon: const Icon(Icons.tune_rounded),
          label: const Text('Ajuste'),
        ),
        if (widget.product.isLowStock)
          OutlinedButton.icon(
            onPressed: _saving
                ? null
                : () => showStockRequestDialog(
                      context,
                      initialProduct: widget.product,
                      initialLocationId: _selectedLocationId,
                    ),
            icon: const Icon(Icons.add_alert_outlined),
            label: const Text('Solicitar reposición'),
          ),
        OutlinedButton.icon(
          onPressed: _saving ? null : _transferStock,
          icon: const Icon(Icons.swap_horiz_rounded),
          label: const Text('Transferir'),
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

  InventoryLocation? get _targetLocation {
    for (final location in widget.locations) {
      if (location.id == _targetLocationId) return location;
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

  String _resolveTargetLocationId() {
    if (widget.locations.length <= 1) return _selectedLocationId;
    for (final location in widget.locations) {
      if (location.id != _selectedLocationId) return location.id;
    }
    return _selectedLocationId;
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

  Future<void> _adjustExact() async {
    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity < 0) {
      await showAppAlertDialog(
        context,
        type: AppAlertType.warning,
        title: 'Cantidad inválida',
        message: 'El ajuste debe ser un número mayor o igual a 0.',
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
    final success = await provider.setProductLocationStock(
      productId: widget.product.id,
      locationId: location.id,
      locationName: location.name,
      quantity: quantity,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (!success) {
      await showAppAlertDialog(
        context,
        type: AppAlertType.error,
        title: 'No se pudo ajustar el stock',
        message:
            provider.error ?? 'No pudimos completar la operación.',
      );
      return;
    }

    await showAppAlertDialog(
      context,
      type: AppAlertType.success,
      title: 'Stock ajustado',
      message:
          'La ubicación quedó ajustada a $quantity unidades correctamente.',
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _transferStock() async {
    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity < 1) {
      await showAppAlertDialog(
        context,
        type: AppAlertType.warning,
        title: 'Cantidad inválida',
        message: 'La transferencia mínima permitida es 1.',
      );
      return;
    }

    final source = _selectedLocation;
    final target = _targetLocation;
    if (source == null || target == null) {
      await showAppAlertDialog(
        context,
        type: AppAlertType.warning,
        title: 'Ubicaciones requeridas',
        message: 'Debes seleccionar origen y destino para transferir stock.',
      );
      return;
    }
    if (source.id == target.id) {
      await showAppAlertDialog(
        context,
        type: AppAlertType.warning,
        title: 'Transferencia inválida',
        message: 'El origen y el destino deben ser ubicaciones diferentes.',
      );
      return;
    }

    final sourceStock =
        widget.product.locationQuantities[source.id]?.quantity ?? 0;
    if (quantity > sourceStock) {
      await showAppAlertDialog(
        context,
        type: AppAlertType.warning,
        title: 'Stock insuficiente',
        message:
            'No puedes mover más stock del disponible en la ubicación origen.',
      );
      return;
    }

    setState(() => _saving = true);
    final provider = context.read<ProductsProvider>();
    final success = await provider.transferProductStock(
      productId: widget.product.id,
      sourceLocationId: source.id,
      sourceLocationName: source.name,
      targetLocationId: target.id,
      targetLocationName: target.name,
      quantity: quantity,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (!success) {
      await showAppAlertDialog(
        context,
        type: AppAlertType.error,
        title: 'No se pudo transferir el stock',
        message: provider.error ?? 'No pudimos completar la transferencia.',
      );
      return;
    }

    await showAppAlertDialog(
      context,
      type: AppAlertType.success,
      title: 'Transferencia registrada',
      message:
          'Se movieron $quantity unidades de ${source.name} a ${target.name}.',
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _stockPill(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label),
    );
  }
}
