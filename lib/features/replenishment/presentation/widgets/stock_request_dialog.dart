import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/core/widgets/app_alert_dialog.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
import 'package:stockmind/features/locations/providers/locations_provider.dart';
import 'package:stockmind/features/products/models/product.dart';
import 'package:stockmind/features/products/providers/products_provider.dart';
import 'package:stockmind/features/replenishment/models/stock_request.dart';
import 'package:stockmind/features/replenishment/providers/stock_requests_provider.dart';

Future<void> showStockRequestDialog(
  BuildContext context, {
  Product? initialProduct,
  String? initialProductId,
  String? initialLocationId,
}) async {
  await showDialog<void>(
    context: context,
    builder: (_) => _StockRequestDialog(
      initialProduct: initialProduct,
      initialProductId: initialProductId,
      initialLocationId: initialLocationId,
    ),
  );
}

class _StockRequestDialog extends StatefulWidget {
  const _StockRequestDialog({
    this.initialProduct,
    this.initialProductId,
    this.initialLocationId,
  });

  final Product? initialProduct;
  final String? initialProductId;
  final String? initialLocationId;

  @override
  State<_StockRequestDialog> createState() => _StockRequestDialogState();
}

class _StockRequestDialogState extends State<_StockRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  final _reasonController = TextEditingController();
  String? _selectedProductId;
  String? _selectedLocationId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedProductId = widget.initialProduct?.id ?? widget.initialProductId;
    _selectedLocationId = widget.initialLocationId;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsProvider = context.watch<ProductsProvider>();
    final requestProvider = context.watch<StockRequestsProvider>();
    final locationsProvider = context.watch<LocationsProvider>();
    final products = productsProvider.products;
    final selectedProduct = _resolveProduct(products);
    final locations = locationsProvider.locations;
    final currentStock = selectedProduct == null || _selectedLocationId == null
        ? 0
        : selectedProduct.locationQuantities[_selectedLocationId!]?.quantity ?? 0;

    return AlertDialog(
      title: const Text('Crear solicitud de reposición'),
      content: SizedBox(
        width: 620,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedProductId,
                        decoration: const InputDecoration(
                          labelText: 'Producto',
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                        ),
                        items: products
                            .map(
                              (product) => DropdownMenuItem<String>(
                                value: product.id,
                                child: Text(product.name),
                              ),
                            )
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedProductId = value;
                                  _selectedLocationId = null;
                                });
                              },
                        validator: (value) =>
                            value == null ? 'Selecciona un producto.' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.tonalIcon(
                      onPressed: _saving ? null : _scanProduct,
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text('Escanear'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _selectedLocationId,
                  decoration: const InputDecoration(
                    labelText: 'Ubicación',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  items: locations
                      .map(
                        (location) => DropdownMenuItem<String>(
                          value: location.id,
                          child: Text(location.name),
                        ),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _selectedLocationId = value),
                  validator: (value) =>
                      value == null ? 'Selecciona una ubicación.' : null,
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Stock actual en ubicación: $currentStock unidades',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad solicitada',
                    prefixIcon: Icon(Icons.add_box_outlined),
                  ),
                  validator: (value) {
                    final parsed = int.tryParse(value ?? '');
                    if (parsed == null || parsed < 1) {
                      return 'La cantidad solicitada debe ser mayor a 0.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _reasonController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Motivo',
                    hintText: 'Ej. reposición por stock bajo o quiebre en tienda',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa un motivo.';
                    }
                    return null;
                  },
                ),
                if (requestProvider.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    requestProvider.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Crear solicitud'),
        ),
      ],
    );
  }

  Product? _resolveProduct(List<Product> products) {
    if (widget.initialProduct != null &&
        (_selectedProductId == null || _selectedProductId == widget.initialProduct!.id)) {
      return widget.initialProduct;
    }
    for (final product in products) {
      if (product.id == _selectedProductId) return product;
    }
    return null;
  }

  Future<void> _scanProduct() async {
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const _ScanBarcodeDialog(),
    );
    if (code == null || !mounted) return;
    final lookup = await context.read<ProductsProvider>().findProductByCode(code);
    if (!mounted) return;
    if (lookup == null) {
      await showAppAlertDialog(
        context,
        type: AppAlertType.warning,
        title: 'Producto no encontrado',
        message: 'No encontramos un producto con ese código para crear la solicitud.',
      );
      return;
    }
    setState(() {
      _selectedProductId = lookup.product.id;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final product = _resolveProduct(context.read<ProductsProvider>().products);
    final location = context
        .read<LocationsProvider>()
        .locations
        .firstWhere((item) => item.id == _selectedLocationId);
    if (product == null || _selectedLocationId == null) return;

    if (context
        .read<StockRequestsProvider>()
        .hasPendingRequestForProductLocation(product.id, _selectedLocationId!)) {
      await showAppAlertDialog(
        context,
        type: AppAlertType.warning,
        title: 'Solicitud duplicada',
        message:
            'Ya existe una solicitud pendiente para este producto en esa ubicación.',
      );
      return;
    }

    final quantity = int.parse(_quantityController.text.trim());
    final auth = context.read<AuthProvider>().user;
    final request = StockRequest(
      id: '',
      productId: product.id,
      productName: product.name,
      barcode: product.barcode,
      locationId: location.id,
      locationName: location.name,
      currentStock: product.locationQuantities[location.id]?.quantity ?? 0,
      requestedQuantity: quantity,
      reason: _reasonController.text.trim(),
      status: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: auth?.id ?? '',
      userName: auth?.displayName ?? auth?.email ?? 'Usuario',
    );

    setState(() => _saving = true);
    final success = await context.read<StockRequestsProvider>().createRequest(request);
    if (!mounted) return;
    setState(() => _saving = false);

    if (!success) {
      await showAppAlertDialog(
        context,
        type: AppAlertType.error,
        title: 'No se pudo crear la solicitud',
        message: context.read<StockRequestsProvider>().error ??
            'No pudimos completar la operación.',
      );
      return;
    }

    await showAppAlertDialog(
      context,
      type: AppAlertType.success,
      title: 'Solicitud creada',
      message: 'La solicitud de reposición fue registrada correctamente.',
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _ScanBarcodeDialog extends StatefulWidget {
  const _ScanBarcodeDialog();

  @override
  State<_ScanBarcodeDialog> createState() => _ScanBarcodeDialogState();
}

class _ScanBarcodeDialogState extends State<_ScanBarcodeDialog> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Escanear producto'),
      content: SizedBox(
        width: 520,
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: MobileScanner(
              controller: _controller,
              onDetect: (capture) async {
                if (_handled || capture.barcodes.isEmpty) return;
                final code = capture.barcodes.first.rawValue?.trim();
                if (code == null || code.isEmpty) return;
                _handled = true;
                await _controller.stop();
                if (context.mounted) {
                  Navigator.of(context).pop(code);
                }
              },
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
