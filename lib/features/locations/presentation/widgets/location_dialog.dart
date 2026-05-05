import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/core/services/storage_service.dart';
import 'package:stockmind/core/widgets/app_alert_dialog.dart';
import 'package:stockmind/core/widgets/remote_image_frame.dart';
import 'package:stockmind/features/locations/models/inventory_location.dart';
import 'package:stockmind/features/locations/providers/locations_provider.dart';

class LocationDialogResult {
  const LocationDialogResult({
    required this.location,
    this.imageFile,
    this.removeImage = false,
  });

  final InventoryLocation location;
  final PickedImageFile? imageFile;
  final bool removeImage;
}

class LocationDialog extends StatefulWidget {
  const LocationDialog({
    this.location,
    super.key,
  });

  final InventoryLocation? location;

  @override
  State<LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends State<LocationDialog>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _customTypeController;
  late String _type;

  PickedImageFile? _pickedImage;
  bool _removeExistingImage = false;
  bool _isPickingImage = false;

  bool get _isCustomType => _type == LocationsProvider.otherLocationType;

  @override
  void initState() {
    super.initState();
    final location = widget.location;
    _nameController = TextEditingController(text: location?.name ?? '');
    _descriptionController =
        TextEditingController(text: location?.description ?? '');
    _customTypeController = TextEditingController();
    _type = location?.type.trim().isNotEmpty ?? false
        ? location!.type.trim()
        : LocationsProvider.baseLocationTypes.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _customTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationTypes = context.watch<LocationsProvider>().locationTypes;
    final selectedType = locationTypes.any(
      (item) => item.toLowerCase() == _type.toLowerCase(),
    )
        ? locationTypes.firstWhere(
            (item) => item.toLowerCase() == _type.toLowerCase(),
          )
        : LocationsProvider.otherLocationType;

    if (selectedType == LocationsProvider.otherLocationType &&
        widget.location != null &&
        _customTypeController.text.isEmpty &&
        _type != LocationsProvider.otherLocationType) {
      _customTypeController.text = _type;
    }

    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      title: Text(widget.location == null ? 'Nueva ubicación' : 'Editar ubicación'),
      content: SizedBox(
        width: 520,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.78,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final useSingleColumn = constraints.maxWidth < 420;
                      final preview = _buildPreview(context);
                      final formFields = Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: 'Nombre'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingresa un nombre para la ubicación.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _descriptionController,
                            minLines: 2,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Descripción',
                            ),
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            initialValue: selectedType,
                            decoration: const InputDecoration(labelText: 'Tipo'),
                            items: locationTypes
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _type = value;
                                  if (value != LocationsProvider.otherLocationType) {
                                    _customTypeController.clear();
                                  }
                                });
                              }
                            },
                          ),
                        ],
                      );

                      if (useSingleColumn) {
                        return Column(
                          children: [
                            preview,
                            const SizedBox(height: 16),
                            formFields,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 148, child: preview),
                          const SizedBox(width: 16),
                          Expanded(child: formFields),
                        ],
                      );
                    },
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, animation) {
                        final slide = Tween<Offset>(
                          begin: const Offset(0, -0.08),
                          end: Offset.zero,
                        ).animate(animation);
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(position: slide, child: child),
                        );
                      },
                      child: _isCustomType
                          ? Padding(
                              key: const ValueKey('custom-type-field'),
                              padding: const EdgeInsets.only(top: 14),
                              child: TextFormField(
                                controller: _customTypeController,
                                decoration: const InputDecoration(
                                  labelText: 'Especificar tipo',
                                  hintText: 'Ej. Despensa, Bodega o Garage',
                                ),
                                validator: (value) {
                                  if (!_isCustomType) return null;
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Debes especificar el tipo';
                                  }
                                  return null;
                                },
                              ),
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('empty-custom-type'),
                            ),
                    ),
                  ),
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
          onPressed: _submit,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _buildPreview(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final imageUrl = _removeExistingImage ? null : widget.location?.imageUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_pickedImage != null)
          Container(
            width: 124,
            height: 124,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.48),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Image.memory(_pickedImage!.bytes, fit: BoxFit.cover),
          )
        else
          RemoteImageFrame(
            size: 124,
            imageUrl: imageUrl,
            icon: _iconForType(_resolvedPreviewType()),
            borderRadius: BorderRadius.circular(22),
          ),
        const SizedBox(height: 12),
        Text('Vista previa', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          'Puedes subir una foto desde tu dispositivo. Si no agregas imagen, verás el ícono del tipo.',
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
            if (_pickedImage != null || imageUrl != null)
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
      if (widget.location?.imageUrl != null) {
        _removeExistingImage = true;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      showAppAlertDialog(
        context,
        type: AppAlertType.warning,
        title: 'Faltan datos de la ubicación',
        message:
            'Debes ingresar el nombre y el tipo de ubicación antes de guardar.',
      );
      return;
    }
    final now = DateTime.now();
    final resolvedType = _isCustomType ? _customTypeController.text.trim() : _type;

    Navigator.of(context).pop(
      LocationDialogResult(
        location: InventoryLocation(
          id: widget.location?.id ?? '',
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          type: resolvedType,
          createdAt: widget.location?.createdAt ?? now,
          updatedAt: now,
          imageUrl: _removeExistingImage ? null : widget.location?.imageUrl,
        ),
        imageFile: _pickedImage,
        removeImage: _removeExistingImage,
      ),
    );
  }

  String _resolvedPreviewType() {
    if (_isCustomType && _customTypeController.text.trim().isNotEmpty) {
      return _customTypeController.text.trim();
    }
    return _type;
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
}
