import 'package:flutter/material.dart';
import 'package:stockmind/models/product.dart';

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
  late final TextEditingController _skuController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _minimumController;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _categoryController = TextEditingController(text: product?.category ?? '');
    _skuController = TextEditingController(text: product?.sku ?? '');
    _priceController = TextEditingController(text: product?.price.toString() ?? '');
    _stockController = TextEditingController(text: product?.stock.toString() ?? '');
    _minimumController =
        TextEditingController(text: product?.minimumStock.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _minimumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Nuevo producto' : 'Editar producto'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                TextFormField(
                  controller: _skuController,
                  decoration: const InputDecoration(labelText: 'SKU'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa un SKU.'
                      : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Precio'),
                        validator: (value) => double.tryParse(value ?? '') == null
                            ? 'Precio inválido.'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Stock'),
                        validator: (value) =>
                            int.tryParse(value ?? '') == null ? 'Stock inválido.' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _minimumController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stock mínimo'),
                  validator: (value) =>
                      int.tryParse(value ?? '') == null ? 'Valor inválido.' : null,
                ),
              ],
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final product = Product(
      id: widget.product?.id ?? '',
      name: _nameController.text.trim(),
      category: _categoryController.text.trim(),
      sku: _skuController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      stock: int.parse(_stockController.text.trim()),
      minimumStock: int.parse(_minimumController.text.trim()),
      createdAt: widget.product?.createdAt ?? now,
      updatedAt: now,
    );
    Navigator.of(context).pop(product);
  }
}
