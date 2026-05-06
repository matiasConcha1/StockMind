import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stockmind/features/products/helpers/stock_status_helper.dart';

class ProductLocationQuantity {
  const ProductLocationQuantity({
    required this.locationId,
    required this.locationName,
    required this.quantity,
  });

  final String locationId;
  final String locationName;
  final int quantity;

  Map<String, dynamic> toMap() {
    return {
      'locationId': locationId,
      'locationName': locationName,
      'quantity': quantity,
    };
  }

  factory ProductLocationQuantity.fromMap(
    String locationId,
    Map<String, dynamic> data,
  ) {
    return ProductLocationQuantity(
      locationId: (data['locationId'] ?? locationId) as String,
      locationName: (data['locationName'] ?? 'Ubicación') as String,
      quantity: ((data['quantity'] ?? 0) as num).toInt(),
    );
  }
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.totalStock,
    required this.minStock,
    required this.status,
    required this.locationQuantities,
    required this.createdAt,
    required this.updatedAt,
    this.expiryDate,
    this.imageUrl,
    this.barcode,
    this.qrCode,
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final int totalStock;
  final int minStock;
  final String status;
  final Map<String, ProductLocationQuantity> locationQuantities;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiryDate;
  final String? imageUrl;
  final String? barcode;
  final String? qrCode;

  int get stock => totalStock;
  StockStatusSummary get stockStatus =>
      resolveStockStatus(stockActual: totalStock, stockMinimo: minStock);
  bool get isLowStock => stockStatus.isOutOfStock || stockStatus.isLowStock;
  bool get isCriticalStock => stockStatus.isOutOfStock;
  bool get isMediumStock => stockStatus.isMediumStock;
  bool get isHighStock => stockStatus.isHighStock;
  bool get hasLocationAssignments => locationQuantities.isNotEmpty;
  double get inventoryValue => price * totalStock;
  bool get hasExpiryDate => expiryDate != null;
  bool get hasBarcode => (barcode?.trim().isNotEmpty ?? false);
  bool get hasQrCode => (qrCode?.trim().isNotEmpty ?? false);

  bool get isExpired =>
      expiryDate != null && _dateOnly(expiryDate!).isBefore(_today);

  bool get expiresWithin7Days =>
      expiryDate != null &&
      !_dateOnly(expiryDate!).isBefore(_today) &&
      !_dateOnly(expiryDate!).isAfter(_today.add(const Duration(days: 7)));

  bool get expiresWithin15Days =>
      expiryDate != null &&
      !_dateOnly(expiryDate!).isBefore(_today) &&
      !_dateOnly(expiryDate!).isAfter(_today.add(const Duration(days: 15)));

  Product copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    int? totalStock,
    int? minStock,
    String? status,
    Map<String, ProductLocationQuantity>? locationQuantities,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiryDate,
    String? imageUrl,
    String? barcode,
    String? qrCode,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      totalStock: totalStock ?? this.totalStock,
      minStock: minStock ?? this.minStock,
      status: status ?? this.status,
      locationQuantities: locationQuantities ?? this.locationQuantities,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiryDate: expiryDate ?? this.expiryDate,
      imageUrl: imageUrl ?? this.imageUrl,
      barcode: barcode ?? this.barcode,
      qrCode: qrCode ?? this.qrCode,
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'totalStock': totalStock,
      'stock': totalStock,
      'minStock': minStock,
      'status': stockStatus.code,
      'expiryDate': expiryDate == null ? null : Timestamp.fromDate(expiryDate!),
      'expirationDate':
          expiryDate == null ? null : Timestamp.fromDate(expiryDate!),
      'locations': _serializeLocations(locationQuantities),
      'imageUrl': imageUrl,
      'barcode': barcode,
      'qrCode': qrCode,
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
      'totalStock': totalStock,
      'stock': totalStock,
      'minStock': minStock,
      'status': stockStatus.code,
      'expiryDate': expiryDate == null ? null : Timestamp.fromDate(expiryDate!),
      'expirationDate':
          expiryDate == null ? null : Timestamp.fromDate(expiryDate!),
      'locations': _serializeLocations(locationQuantities),
      'imageUrl': imageUrl,
      'barcode': barcode,
      'qrCode': qrCode,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final totalStock = ((data['totalStock'] ?? data['stock'] ?? 0) as num).toInt();
    final minStock =
        ((data['minStock'] ?? data['minimumStock'] ?? 0) as num).toInt();
    final rawLocations = (data['locations'] as Map<String, dynamic>?) ?? const {};
    final locationQuantities = <String, ProductLocationQuantity>{};

    for (final entry in rawLocations.entries) {
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        locationQuantities[entry.key] =
            ProductLocationQuantity.fromMap(entry.key, value);
      } else if (value is Map) {
        locationQuantities[entry.key] = ProductLocationQuantity.fromMap(
          entry.key,
          value.map((key, item) => MapEntry(key.toString(), item)),
        );
      }
    }

    return Product(
      id: (data['id'] ?? doc.id) as String,
      name: (data['name'] ?? '') as String,
      category: (data['category'] ?? 'General') as String,
      price: ((data['price'] ?? 0) as num).toDouble(),
      totalStock: totalStock,
      minStock: minStock,
      status: (data['status'] ??
              resolveStockStatus(stockActual: totalStock, stockMinimo: minStock)
                  .code)
          as String,
      locationQuantities: locationQuantities,
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDate(data['updatedAt']),
      expiryDate:
          _toNullableDate(data['expirationDate']) ?? _toNullableDate(data['expiryDate']),
      imageUrl: (data['imageUrl'] as String?)?.trim().isEmpty ?? true
          ? null
          : data['imageUrl'] as String,
      barcode: (data['barcode'] as String?)?.trim().isEmpty ?? true
          ? null
          : data['barcode'] as String,
      qrCode: (data['qrCode'] as String?)?.trim().isEmpty ?? true
          ? null
          : data['qrCode'] as String,
    );
  }

  static Map<String, dynamic> _serializeLocations(
    Map<String, ProductLocationQuantity> items,
  ) {
    return {
      for (final entry in items.entries) entry.key: entry.value.toMap(),
    };
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

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static DateTime get _today => _dateOnly(DateTime.now());
}
