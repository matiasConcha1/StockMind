import 'package:cloud_firestore/cloud_firestore.dart';

class StockMovement {
  const StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String productName;
  final String type;
  final int quantity;
  final int previousStock;
  final int newStock;
  final String reason;
  final DateTime createdAt;

  bool get isEntry => type == 'entrada';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'type': type,
      'quantity': quantity,
      'previousStock': previousStock,
      'newStock': newStock,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory StockMovement.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return StockMovement(
      id: (data['id'] ?? doc.id) as String,
      productId: (data['productId'] ?? '') as String,
      productName: (data['productName'] ?? '') as String,
      type: (data['type'] ?? 'entrada') as String,
      quantity: ((data['quantity'] ?? 0) as num).toInt(),
      previousStock: ((data['previousStock'] ?? 0) as num).toInt(),
      newStock: ((data['newStock'] ?? 0) as num).toInt(),
      reason: (data['reason'] ?? 'Ajuste manual de stock') as String,
      createdAt: _toDate(data['createdAt']),
    );
  }

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
