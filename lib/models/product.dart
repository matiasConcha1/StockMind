class Product {
  const Product({
    required this.id,
    required this.name,
    required this.quantity,
    required this.minimumStock,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final int quantity;
  final int minimumStock;
  final DateTime updatedAt;

  bool get isLowStock => quantity <= minimumStock;

  Product copyWith({
    String? id,
    String? name,
    int? quantity,
    int? minimumStock,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      minimumStock: minimumStock ?? this.minimumStock,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
