import 'package:cloud_firestore/cloud_firestore.dart';

class StockAlert {
  const StockAlert({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
    required this.currentStock,
    required this.minStock,
    required this.status,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
    this.expiryDate,
  });

  final String id;
  final String productId;
  final String productName;
  final String type;
  final String title;
  final String message;
  final String severity;
  final int currentStock;
  final int minStock;
  final String status;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiryDate;

  bool get isResolved => status == 'resolved';
  bool get isActive => status == 'active';
  bool get isCritical => severity == 'critical';
  bool get isHigh => severity == 'high';
  bool get isMedium => severity == 'medium';
  bool get isExpiryAlert =>
      type == 'producto_vencido' ||
      type == 'vence_pronto' ||
      type == 'vencimiento_warning';

  factory StockAlert.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return StockAlert(
      id: (data['id'] ?? doc.id) as String,
      productId: (data['productId'] ?? '') as String,
      productName: (data['productName'] ?? 'Producto') as String,
      type: (data['type'] ?? 'bajo_stock') as String,
      title: (data['title'] ?? 'Alerta de stock') as String,
      message: (data['message'] ?? '') as String,
      severity: (data['severity'] ?? 'medium') as String,
      currentStock: ((data['currentStock'] ?? 0) as num).toInt(),
      minStock: ((data['minStock'] ?? 0) as num).toInt(),
      status: (data['status'] ?? 'active') as String,
      isRead: (data['isRead'] ?? false) as bool,
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDate(data['updatedAt']),
      expiryDate: _toNullableDate(data['expiryDate']),
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
