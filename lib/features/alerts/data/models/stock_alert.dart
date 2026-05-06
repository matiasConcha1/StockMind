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
    this.resolvedAt,
    this.resolvedBy,
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
  final DateTime? resolvedAt;
  final String? resolvedBy;

  bool get isResolved => status == 'resolved';
  bool get isActive => status == 'active';
  bool get isLowSeverity => severity == 'low';
  bool get isMedium => severity == 'medium';
  bool get isHigh => severity == 'high';
  bool get isExpired => type == 'expired';
  bool get isExpiringSoon => type == 'expiring_soon';
  bool get isLowStock => type == 'low_stock';
  bool get isExpiryAlert => isExpired || isExpiringSoon;

  factory StockAlert.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return StockAlert(
      id: (data['id'] ?? doc.id) as String,
      productId: (data['productId'] ?? '') as String,
      productName: (data['productName'] ?? 'Producto') as String,
      type: _normalizeType((data['type'] ?? 'low_stock') as String),
      title: (data['title'] ?? 'Alerta de inventario') as String,
      message: (data['message'] ?? '') as String,
      severity: _normalizeSeverity((data['severity'] ?? 'medium') as String),
      currentStock: ((data['currentStock'] ?? 0) as num).toInt(),
      minStock: ((data['minStock'] ?? 0) as num).toInt(),
      status: (data['status'] ?? 'active') as String,
      isRead: (data['isRead'] ?? false) as bool,
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDate(data['updatedAt']),
      expiryDate:
          _toNullableDate(data['expirationDate']) ?? _toNullableDate(data['expiryDate']),
      resolvedAt: _toNullableDate(data['resolvedAt']),
      resolvedBy: (data['resolvedBy'] as String?)?.trim().isEmpty ?? true
          ? null
          : data['resolvedBy'] as String,
    );
  }

  static String _normalizeType(String value) {
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'sin_stock':
      case 'bajo_stock':
      case 'stock_medio':
      case 'low_stock':
        return 'low_stock';
      case 'producto_vencido':
      case 'expired':
        return 'expired';
      case 'vence_pronto':
      case 'vencimiento_warning':
      case 'expiring_soon':
        return 'expiring_soon';
      default:
        return normalized.isEmpty ? 'low_stock' : normalized;
    }
  }

  static String _normalizeSeverity(String value) {
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'critical':
        return 'high';
      case 'high':
      case 'medium':
      case 'low':
        return normalized;
      default:
        return 'medium';
    }
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
