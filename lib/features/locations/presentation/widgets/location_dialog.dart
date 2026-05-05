import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/core/widgets/remote_image_frame.dart';
import 'package:stockmind/features/locations/models/inventory_location.dart';
import 'package:stockmind/features/locations/providers/locations_provider.dart';

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
  late final TextEditingController _imageUrlController;
  late String _type;

  bool get _isCustomType => _type == LocationsProvider.otherLocationType;

  @override
  void initState() {
    super.initState();
    final location = widget.location;
    _nameController = TextEditingController(text: location?.name ?? '');
    _descriptionController =
        TextEditingController(text: location?.description ?? '');
    _customTypeController = TextEditingController();
    _imageUrlController = TextEditingController(text: location?.imageUrl ?? '');
    _type = location?.type.trim().isNotEmpty ?? false
        ? location!.type.trim()
        : LocationsProvider.baseLocationTypes.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _customTypeController.dispose();
    _imageUrlController.dispose();
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
                          TextFormField(
                            controller: _imageUrlController,
                            keyboardType: TextInputType.url,
                            decoration: const InputDecoration(
                              labelText: 'Foto de ubicación',
                              hintText: 'https://...',
                              prefixIcon: Icon(Icons.image_outlined),
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: _validateOptionalUrl,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RemoteImageFrame(
          size: 124,
          imageUrl: _imageUrlController.text.trim(),
          icon: _iconForType(_resolvedPreviewType()),
          borderRadius: BorderRadius.circular(22),
        ),
        const SizedBox(height: 12),
        Text('Vista previa', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          'Puedes usar una foto del refrigerador, caja o zona física. Si no agregas imagen, verás un ícono del tipo.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final resolvedType = _isCustomType ? _customTypeController.text.trim() : _type;

    Navigator.of(context).pop(
      InventoryLocation(
        id: widget.location?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: resolvedType,
        createdAt: widget.location?.createdAt ?? now,
        updatedAt: now,
        imageUrl: _normalizedUrl(_imageUrlController.text),
      ),
    );
  }

  String _resolvedPreviewType() {
    if (_isCustomType && _customTypeController.text.trim().isNotEmpty) {
      return _customTypeController.text.trim();
    }
    return _type;
  }

  String? _validateOptionalUrl(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'Ingresa una URL válida.';
    }
    return null;
  }

  String? _normalizedUrl(String raw) {
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
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
