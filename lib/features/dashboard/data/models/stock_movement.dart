import 'package:cloud_firestore/cloud_firestore.dart';

class StockMovement {
  const StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    this.barcode,
    required this.type,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    required this.reason,
    required this.locationId,
    required this.locationName,
    this.sourceLocationId,
    this.sourceLocationName,
    this.targetLocationId,
    this.targetLocationName,
    required this.previousQuantityInLocation,
    required this.newQuantityInLocation,
    required this.previousTotalStock,
    required this.newTotalStock,
    required this.createdAt,
    this.updatedAt,
    this.userId,
    this.userName,
  });

  final String id;
  final String productId;
  final String productName;
  final String? barcode;
  final String type;
  final int quantity;
  final int previousStock;
  final int newStock;
  final String reason;
  final String locationId;
  final String locationName;
  final String? sourceLocationId;
  final String? sourceLocationName;
  final String? targetLocationId;
  final String? targetLocationName;
  final int previousQuantityInLocation;
  final int newQuantityInLocation;
  final int previousTotalStock;
  final int newTotalStock;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? userId;
  final String? userName;

  String get normalizedType {
    switch (type) {
      case 'entrada':
        return 'entry';
      case 'salida':
        return 'exit';
      default:
        return type;
    }
  }

  bool get isEntry => normalizedType == 'entry';
  bool get isExit => normalizedType == 'exit';
  bool get isAdjustment => normalizedType == 'adjustment';
  bool get isExpired => normalizedType == 'expired';
  bool get isDamaged => normalizedType == 'damaged';
  bool get isTransfer => normalizedType == 'transfer';
  int get updatedStock => newTotalStock;
  bool get hasLocationContext => locationId.isNotEmpty || locationName.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'barcode': barcode,
      'type': normalizedType,
      'quantity': quantity,
      'previousStock': previousStock,
      'newStock': newStock,
      'reason': reason,
      'locationId': locationId,
      'locationName': locationName,
      'sourceLocationId': sourceLocationId,
      'sourceLocationName': sourceLocationName,
      'targetLocationId': targetLocationId,
      'targetLocationName': targetLocationName,
      'previousQuantityInLocation': previousQuantityInLocation,
      'newQuantityInLocation': newQuantityInLocation,
      'previousTotalStock': previousTotalStock,
      'newTotalStock': newTotalStock,
      'updatedStock': updatedStock,
      'userId': userId,
      'userName': userName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory StockMovement.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return StockMovement(
      id: (data['id'] ?? doc.id) as String,
      productId: (data['productId'] ?? '') as String,
      productName: (data['productName'] ?? '') as String,
      barcode: (data['barcode'] as String?)?.trim().isEmpty ?? true
          ? null
          : data['barcode'] as String,
      type: (data['type'] ?? 'entrada') as String,
      quantity: ((data['quantity'] ?? 0) as num).toInt(),
      previousStock: ((data['previousStock'] ?? data['previousTotalStock'] ?? 0)
              as num)
          .toInt(),
      newStock: ((data['newStock'] ?? data['newTotalStock'] ?? 0) as num).toInt(),
      reason: (data['reason'] ?? 'Ajuste manual de stock') as String,
      locationId: (data['locationId'] ?? '') as String,
      locationName: (data['locationName'] ?? '') as String,
      sourceLocationId: (data['sourceLocationId'] as String?)?.trim().isEmpty ?? true
          ? null
          : data['sourceLocationId'] as String,
      sourceLocationName:
          (data['sourceLocationName'] as String?)?.trim().isEmpty ?? true
              ? null
              : data['sourceLocationName'] as String,
      targetLocationId: (data['targetLocationId'] as String?)?.trim().isEmpty ?? true
          ? null
          : data['targetLocationId'] as String,
      targetLocationName:
          (data['targetLocationName'] as String?)?.trim().isEmpty ?? true
              ? null
              : data['targetLocationName'] as String,
      previousQuantityInLocation:
          ((data['previousQuantityInLocation'] ?? 0) as num).toInt(),
      newQuantityInLocation:
          ((data['newQuantityInLocation'] ?? 0) as num).toInt(),
      previousTotalStock:
          ((data['previousTotalStock'] ?? data['previousStock'] ?? 0) as num)
              .toInt(),
      newTotalStock:
          ((data['newTotalStock'] ?? data['newStock'] ?? 0) as num).toInt(),
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toNullableDate(data['updatedAt']),
      userId: (data['userId'] as String?)?.trim().isEmpty ?? true
          ? null
          : data['userId'] as String,
      userName: (data['userName'] as String?)?.trim().isEmpty ?? true
          ? null
          : data['userName'] as String,
    );
  }

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  static DateTime? _toNullableDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
