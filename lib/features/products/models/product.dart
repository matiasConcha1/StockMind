import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.minStock,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final int stock;
  final int minStock;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isLowStock => stock <= minStock;
  double get inventoryValue => price * stock;

  Product copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    int? stock,
    int? minStock,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'stock': stock,
      'minStock': minStock,
      'status': _resolveStatus(stock: stock, minStock: minStock),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'stock': stock,
      'minStock': minStock,
      'status': _resolveStatus(stock: stock, minStock: minStock),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final stock = ((data['stock'] ?? 0) as num).toInt();
    final minStock = ((data['minStock'] ?? data['minimumStock'] ?? 0) as num)
        .toInt();

    return Product(
      id: (data['id'] ?? doc.id) as String,
      name: (data['name'] ?? '') as String,
      category: (data['category'] ?? 'General') as String,
      price: ((data['price'] ?? 0) as num).toDouble(),
      stock: stock,
      minStock: minStock,
      status: (data['status'] ?? _resolveStatus(stock: stock, minStock: minStock))
          as String,
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDate(data['updatedAt']),
    );
  }

  static String _resolveStatus({
    required int stock,
    required int minStock,
  }) {
    return stock <= minStock ? 'low' : 'ok';
  }

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
