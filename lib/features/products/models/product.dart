import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.sku,
    required this.price,
    required this.stock,
    required this.minimumStock,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String category;
  final String sku;
  final double price;
  final int stock;
  final int minimumStock;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isLowStock => stock <= minimumStock;
  double get inventoryValue => price * stock;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'sku': sku,
      'price': price,
      'stock': stock,
      'minimumStock': minimumStock,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Product(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      category: (data['category'] ?? 'General') as String,
      sku: (data['sku'] ??
          doc.id.substring(0, doc.id.length > 8 ? 8 : doc.id.length)) as String,
      price: ((data['price'] ?? 0) as num).toDouble(),
      stock: ((data['stock'] ?? 0) as num).toInt(),
      minimumStock: ((data['minimumStock'] ?? 0) as num).toInt(),
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDate(data['updatedAt']),
    );
  }

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
