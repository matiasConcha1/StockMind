import 'package:cloud_firestore/cloud_firestore.dart';

class StockRequest {
  const StockRequest({
    required this.id,
    required this.productId,
    required this.productName,
    this.barcode,
    required this.locationId,
    required this.locationName,
    required this.currentStock,
    required this.requestedQuantity,
    required this.reason,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    required this.userId,
    required this.userName,
  });

  final String id;
  final String productId;
  final String productName;
  final String? barcode;
  final String locationId;
  final String locationName;
  final int currentStock;
  final int requestedQuantity;
  final String reason;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final String userId;
  final String userName;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  StockRequest copyWith({
    String? id,
    String? productId,
    String? productName,
    String? barcode,
    String? locationId,
    String? locationName,
    int? currentStock,
    int? requestedQuantity,
    String? reason,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    String? userId,
    String? userName,
  }) {
    return StockRequest(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      barcode: barcode ?? this.barcode,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      currentStock: currentStock ?? this.currentStock,
      requestedQuantity: requestedQuantity ?? this.requestedQuantity,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'barcode': barcode,
      'locationId': locationId,
      'locationName': locationName,
      'currentStock': currentStock,
      'requestedQuantity': requestedQuantity,
      'reason': reason,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'completedAt': completedAt == null ? null : Timestamp.fromDate(completedAt!),
      'userId': userId,
      'userName': userName,
    };
  }

  factory StockRequest.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return StockRequest(
      id: (data['id'] ?? doc.id) as String,
      productId: (data['productId'] ?? '') as String,
      productName: (data['productName'] ?? '') as String,
      barcode: (data['barcode'] as String?)?.trim().isEmpty ?? true
          ? null
          : data['barcode'] as String,
      locationId: (data['locationId'] ?? '') as String,
      locationName: (data['locationName'] ?? '') as String,
      currentStock: ((data['currentStock'] ?? 0) as num).toInt(),
      requestedQuantity: ((data['requestedQuantity'] ?? 0) as num).toInt(),
      reason: (data['reason'] ?? '') as String,
      status: (data['status'] ?? 'pending') as String,
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDate(data['updatedAt']),
      completedAt: _toNullableDate(data['completedAt']),
      userId: (data['userId'] ?? '') as String,
      userName: (data['userName'] ?? '') as String,
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
