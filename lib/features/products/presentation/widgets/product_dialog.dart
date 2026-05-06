import 'dart:math' as math;

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stockmind/app/routes.dart';
import 'package:stockmind/core/services/storage_service.dart';
import 'package:stockmind/core/widgets/app_alert_dialog.dart';
import 'package:stockmind/core/widgets/remote_image_frame.dart';
import 'package:stockmind/features/locations/models/inventory_location.dart';
import 'package:stockmind/features/locations/providers/locations_provider.dart';
import 'package:stockmind/features/products/helpers/product_code_helper.dart';
import 'package:stockmind/features/products/helpers/stock_status_helper.dart';
import 'package:stockmind/features/products/models/product.dart';

class ProductDialogResult {
  const ProductDialogResult({
    required this.product,
    this.stockChangeReason,
    this.imageFile,
    this.removeImage = false,
  });

  final Product product;
  final String? stockChangeReason;
  final PickedImageFile? imageFile;
  final bool removeImage;
}

class ProductDialog extends StatefulWidget {
  const ProductDialog({
    this.product,
    this.initialBarcode,
    super.key,
  });

  final Product? product;
  final String? initialBarcode;

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
  late final TextEditingController _codeController;
  final Map<String, TextEditingController> _locationControllers = {};
  DateTime? _expiryDate;
  late final String _generatedFallbackCode;

  PickedImageFile? _pickedImage;
  bool _removeExistingImage = false;
  bool _isPickingImage = false;

  String get _resolvedProductCode {
    final manualCode = _codeController.text.trim();
    return manualCode.isNotEmpty ? manualCode : _generatedFallbackCode;
  }

  String get _draftBarcode => _resolvedProductCode;
  String get _draftQrCode => _resolvedProductCode;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _categoryController = TextEditingController(text: product?.category ?? '');
    _priceController = TextEditingController(text: product?.price.toString() ?? '');
    _minStockController = TextEditingController(
      text: product?.minStock.toString() ?? '',
    );
    _reasonController = TextEditingController();
    _expiryDate = product?.expiryDate;
    final initialCode = (product?.barcode?.trim().isNotEmpty ?? false)
        ? product!.barcode!.trim()
        : (product?.qrCode?.trim().isNotEmpty ?? false)
            ? product!.qrCode!.trim()
            : (widget.initialBarcode?.trim() ?? '');
    _generatedFallbackCode = initialCode.isNotEmpty
        ? initialCode
        : generateBarcodeValue();
    _codeController = TextEditingController(text: initialCode);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _minStockController.dispose();
    _reasonController.dispose();
    _codeController.dispose();
    for (final controller in _locationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.product == null ? 'Nuevo producto' : 'Editar producto'),
          const SizedBox(height: 6),
          Text(
            'Define la información base, agrega una imagen opcional y distribuye el inventario entre tus ubicaciones.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 760,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBasicsSection(context),
                  const SizedBox(height: 20),
                  _buildIdentificationSection(context),
                  const SizedBox(height: 20),
                  _buildDistributionSection(
                    context: context,
                    locations: locations,
                    hasLocations: hasLocations,
                    inheritedUnassignedStock: inheritedUnassignedStock,
                  ),
                  const SizedBox(height: 18),
                  _buildTotalStockCard(context, distributedTotal),
                  if (widget.product != null) ...[
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _reasonController,
                      minLines: 2,
                      maxLines: 3,
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

  Widget _buildBasicsSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useSingleColumn = constraints.maxWidth < 620;
        final imagePreview = _buildImagePanel(context);

        final formContent = Column(
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
              decoration: const InputDecoration(
                labelText: 'Categoría',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Ingresa una categoría.'
                  : null,
            ),
            const SizedBox(height: 14),
            _buildExpiryField(context),
            const SizedBox(height: 14),
            if (useSingleColumn) ...[
              _buildPriceField(),
              const SizedBox(height: 14),
              _buildMinStockField(),
            ] else
              Row(
                children: [
                  Expanded(child: _buildPriceField()),
                  const SizedBox(width: 14),
                  Expanded(child: _buildMinStockField()),
                ],
              ),
          ],
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: useSingleColumn
              ? Column(
                  children: [
                    imagePreview,
                    const SizedBox(height: 16),
                    formContent,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 180, child: imagePreview),
                    const SizedBox(width: 18),
                    Expanded(child: formContent),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildImagePanel(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasExistingNetworkImage =
        widget.product?.imageUrl != null && !_removeExistingImage;
    final hasAnyImage = _pickedImage != null || hasExistingNetworkImage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LocalAwarePreview(
          size: 148,
          pickedImage: _pickedImage,
          imageUrl: hasExistingNetworkImage ? widget.product?.imageUrl : null,
          icon: Icons.inventory_2_outlined,
        ),
        const SizedBox(height: 12),
        Text('Imagen del producto', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          'Puedes subir una imagen desde tu dispositivo. Máximo 5 MB en JPG, PNG o WEBP.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.tonalIcon(
              onPressed: _isPickingImage ? null : () => _pickImage(context),
              icon: _isPickingImage
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_outlined),
              label: Text(_isPickingImage ? 'Cargando...' : 'Subir imagen'),
            ),
            if (hasAnyImage)
              OutlinedButton.icon(
                onPressed: _clearImage,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Quitar imagen'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Precio',
        prefixText: '\$ ',
      ),
      validator: (value) {
        final parsed = double.tryParse(value ?? '');
        if (parsed == null) return 'Precio inválido.';
        if (parsed < 0) return 'El precio debe ser mayor o igual a 0.';
        return null;
      },
    );
  }

  Widget _buildMinStockField() {
    return TextFormField(
      controller: _minStockController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(labelText: 'Stock mínimo'),
      validator: (value) {
        final parsed = int.tryParse(value ?? '');
        if (parsed == null) return 'Valor inválido.';
        if (parsed < 0) {
          return 'El stock mínimo debe ser mayor o igual a 0.';
        }
        return null;
      },
    );
  }

  Widget _buildExpiryField(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final label = _expiryDate == null
        ? 'Sin fecha de vencimiento'
        : '${_expiryDate!.day.toString().padLeft(2, '0')}/${_expiryDate!.month.toString().padLeft(2, '0')}/${_expiryDate!.year}';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _pickExpiryDate(context),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Fecha de vencimiento',
          prefixIcon: Icon(Icons.event_available_outlined),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: _expiryDate == null
                      ? colorScheme.onSurface.withValues(alpha: 0.68)
                      : colorScheme.onSurface,
                ),
              ),
            ),
            if (_expiryDate != null)
              IconButton(
                onPressed: () => setState(() => _expiryDate = null),
                icon: const Icon(Icons.close_rounded),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionSection({
    required BuildContext context,
    required List<InventoryLocation> locations,
    required bool hasLocations,
    required int inheritedUnassignedStock,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.hub_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Distribución por ubicación',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Asigna cantidades por ubicación. El stock total se calcula automáticamente.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildInfoChip(
                context,
                icon: Icons.inventory_2_outlined,
                label: '${locations.length} ubicaciones',
              ),
              _buildInfoChip(
                context,
                icon: Icons.calculate_rounded,
                label: '${_computeDistributedTotal()} unidades asignadas',
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!hasLocations)
            _buildEmptyLocationsState(context)
          else ...[
            if (inheritedUnassignedStock > 0) ...[
              _buildLegacyStockBanner(context, inheritedUnassignedStock),
              const SizedBox(height: 14),
            ],
            LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                final columns = availableWidth >= 620 ? 2 : 1;
                final cardWidth = columns == 2
                    ? (availableWidth - 12) / 2
                    : availableWidth;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final location in locations)
                      SizedBox(
                        width: math.max(0, cardWidth),
                        child: _buildLocationCard(context, location),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIdentificationSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Identificación del producto',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Cada producto cuenta con un código de barras y un QR para escanearlo rápidamente.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 640;
              final codeInfo = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCodeReadOnlyField(
                    context,
                    label: 'Código de barras',
                    value: _draftBarcode,
                  ),
                  const SizedBox(height: 12),
                  _buildCodeReadOnlyField(
                    context,
                    label: 'QR del producto',
                    value: _draftQrCode,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () => _showQrPreview(context),
                        icon: const Icon(Icons.qr_code_2_rounded),
                        label: const Text('Ver QR'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => _showBarcodePreview(context),
                        icon: const Icon(Icons.view_week_outlined),
                        label: const Text('Ver código de barras'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _copyCode(context, _draftBarcode),
                        icon: const Icon(Icons.copy_all_outlined),
                        label: const Text('Copiar código'),
                      ),
                    ],
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    codeInfo,
                    const SizedBox(height: 16),
                    Center(
                      child: _CodePreviewRail(
                        barcodeValue: _draftBarcode,
                        qrValue: _draftQrCode,
                        compact: true,
                      ),
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: codeInfo),
                  const SizedBox(width: 16),
                  _CodePreviewRail(
                    barcodeValue: _draftBarcode,
                    qrValue: _draftQrCode,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCodeReadOnlyField(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final isBarcodeField = label.toLowerCase().contains('barras');
    if (isBarcodeField) {
      return TextFormField(
        controller: _codeController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: 'Código del producto',
          helperText:
              'Solo números. Se usará también para el QR y el copiado.',
          suffixIcon: IconButton(
            onPressed: () => _copyCode(context, _resolvedProductCode),
            icon: const Icon(Icons.copy_rounded),
          ),
        ),
        validator: (fieldValue) {
          final trimmed = fieldValue?.trim() ?? '';
          if (trimmed.isEmpty) return null;
          if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
            return 'El código solo puede contener números.';
          }
          return null;
        },
      );
    }

    return TextFormField(
      key: ValueKey('$label-${_resolvedProductCode}'),
      initialValue: _resolvedProductCode,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          onPressed: () => _copyCode(context, _resolvedProductCode),
          icon: const Icon(Icons.copy_rounded),
        ),
      ),
    );
  }

  Widget _buildEmptyLocationsState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.location_on_outlined,
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Primero debes crear una ubicación desde la sección Ubicaciones.',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Cuando exista al menos una ubicación, podrás asignar cantidades a este producto y calcular su stock total automáticamente.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.tonalIcon(
            onPressed: () {
              Navigator.of(context).pop();
              context.go(AppRoutePaths.locations);
            },
            icon: const Icon(Icons.location_on_outlined),
            label: const Text('Ir a Ubicaciones'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegacyStockBanner(BuildContext context, int inheritedUnassignedStock) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: colorScheme.onSecondaryContainer,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Este producto tiene $inheritedUnassignedStock unidades heredadas sin ubicar. Distribúyelas para dejar el inventario consistente.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, InventoryLocation location) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final controller = _locationControllers[location.id]!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RemoteImageFrame(
                size: 52,
                imageUrl: location.imageUrl,
                icon: _iconForType(location.type),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
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
                            location.type,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        if (location.description.trim().isNotEmpty)
                          Text(
                            location.description.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.68),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Cantidad',
              hintText: '0',
              suffixText: 'unid.',
            ),
            onChanged: (_) => setState(() {}),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return null;
              final parsed = int.tryParse(value);
              if (parsed == null) return 'Cantidad inválida.';
              if (parsed < 0) return 'La cantidad debe ser mayor o igual a 0.';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTotalStockCard(BuildContext context, int distributedTotal) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.inventory_2_outlined, color: colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stock total',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$distributedTotal unidades',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Se actualiza automáticamente con la suma de todas las ubicaciones.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final storageService = context.read<StorageService>();
    setState(() => _isPickingImage = true);
    try {
      final picked = await storageService.pickImage();
      if (!mounted || picked == null) return;
      setState(() {
        _pickedImage = picked;
        _removeExistingImage = false;
      });
    } on StorageServiceException catch (error) {
      if (!mounted) return;
      await showAppAlertDialog(
        context,
        type: AppAlertType.error,
        title: 'Error al cargar imagen',
        message: error.message,
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  void _clearImage() {
    setState(() {
      _pickedImage = null;
      if (widget.product?.imageUrl != null) {
        _removeExistingImage = true;
      }
    });
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
    if (!_formKey.currentState!.validate()) {
      showAppAlertDialog(
        context,
        type: AppAlertType.warning,
        title: 'Faltan datos del producto',
        message:
            'Debes ingresar el nombre, precio, stock y stock mínimo antes de guardar.',
      );
      return;
    }

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
      showAppAlertDialog(
        context,
        type: AppAlertType.warning,
        title: 'Distribución incompleta',
        message:
            'Debes asignar al menos una ubicación con cantidad mayor a 0 antes de guardar.',
      );
      return;
    }

    final totalStock = locationQuantities.values.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    final minStock = int.parse(_minStockController.text.trim());
    final now = DateTime.now();
    final productCode = _resolvedProductCode;

    final product = Product(
      id: widget.product?.id ?? '',
      name: _nameController.text.trim(),
      category: _categoryController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      totalStock: totalStock,
      minStock: minStock,
      status: resolveStockStatus(
        stockActual: totalStock,
        stockMinimo: minStock,
      ).code,
      locationQuantities: locationQuantities,
      createdAt: widget.product?.createdAt ?? now,
      updatedAt: now,
      imageUrl: _removeExistingImage ? null : widget.product?.imageUrl,
      expiryDate: _expiryDate,
      barcode: productCode,
      qrCode: productCode,
    );

    Navigator.of(context).pop(
      ProductDialogResult(
        product: product,
        stockChangeReason: _reasonController.text.trim(),
        imageFile: _pickedImage,
        removeImage: _removeExistingImage,
      ),
    );
  }

  IconData _iconForType(String type) {
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

  Future<void> _pickExpiryDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _expiryDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _copyCode(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    await showAppAlertDialog(
      context,
      type: AppAlertType.success,
      title: 'Código copiado',
      message: 'El código fue copiado al portapapeles.',
    );
  }

  Future<void> _showQrPreview(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _CodePreviewDialog(
        title: 'QR del producto',
        child: QrImageView(
          data: _draftQrCode,
          version: QrVersions.auto,
          size: 220,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  Future<void> _showBarcodePreview(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _CodePreviewDialog(
        title: 'Código de barras',
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: BarcodeWidget(
            barcode: Barcode.code128(),
            data: _draftBarcode,
            width: 320,
            height: 120,
            drawText: true,
          ),
        ),
      ),
    );
  }
}

class _LocalAwarePreview extends StatelessWidget {
  const _LocalAwarePreview({
    required this.size,
    required this.icon,
    this.pickedImage,
    this.imageUrl,
  });

  final double size;
  final PickedImageFile? pickedImage;
  final String? imageUrl;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (pickedImage != null) {
      return Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.48),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Image.memory(
          pickedImage!.bytes,
          fit: BoxFit.cover,
        ),
      );
    }

    return RemoteImageFrame(
      size: size,
      imageUrl: imageUrl,
      icon: icon,
      borderRadius: BorderRadius.circular(24),
    );
  }
}

class _CodePreviewRail extends StatelessWidget {
  const _CodePreviewRail({
    required this.barcodeValue,
    required this.qrValue,
    this.compact = false,
  });

  final String barcodeValue;
  final String qrValue;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: compact ? 220 : 180,
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8),
            child: QrImageView(
              data: qrValue,
              version: QrVersions.auto,
              size: compact ? 132 : 110,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: BarcodeWidget(
              barcode: Barcode.code128(),
              data: barcodeValue,
              width: compact ? 164 : 132,
              height: compact ? 64 : 56,
              drawText: compact,
            ),
          ),
        ],
      ),
    );
  }
}

class _CodePreviewDialog extends StatelessWidget {
  const _CodePreviewDialog({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: Center(child: child)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
