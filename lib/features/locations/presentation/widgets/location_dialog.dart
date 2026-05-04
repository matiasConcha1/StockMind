import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

    return AlertDialog(
      title: Text(
        widget.location == null ? 'Nueva ubicación' : 'Editar ubicación',
      ),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                decoration: const InputDecoration(labelText: 'Descripción'),
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
                      : const SizedBox.shrink(key: ValueKey('empty-custom-type')),
                ),
              ),
            ],
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
      ),
    );
  }
}
