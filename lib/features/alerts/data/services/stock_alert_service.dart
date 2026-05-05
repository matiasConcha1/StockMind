import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:stockmind/features/alerts/data/models/stock_alert.dart';
import 'package:stockmind/features/products/models/product.dart';

class StockAlertService {
  StockAlertService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore.collection('users').doc(userId).collection('alerts');
  }

  Stream<List<StockAlert>> watchAlerts(String userId) {
    debugPrint('StockAlertService.watchAlerts: userId=$userId');
    return _collection(userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(StockAlert.fromFirestore).toList());
  }

  Future<void> syncProductAlerts(String userId, Product product) async {
    debugPrint(
      'StockAlertService.syncProductAlerts: userId=$userId productId=${product.id}',
    );
    await _syncStockAlert(userId, product);
    await _syncExpiryAlert(userId, product);
  }

  Future<void> deleteAlertsForProduct(String userId, String productId) async {
    final batch = _firestore.batch();
    for (final suffix in const ['stock', 'expiry']) {
      batch.delete(_collection(userId).doc('${productId}_$suffix'));
    }
    await batch.commit();
  }

  Future<void> markAsRead(String userId, String alertId) async {
    await _collection(userId).doc(alertId).set(
      {
        'isRead': true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> resolveAlert(String userId, String alertId) async {
    await _collection(userId).doc(alertId).set(
      {
        'status': 'resolved',
        'isRead': true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _syncStockAlert(String userId, Product product) async {
    final status = product.stockStatus;
    final docRef = _collection(userId).doc('${product.id}_stock');
    final snapshot = await docRef.get();
    final existing = snapshot.data() ?? <String, dynamic>{};
    final currentType = switch (status.code) {
      'sin_stock' => 'sin_stock',
      'bajo_stock' => 'bajo_stock',
      'stock_medio' => 'stock_medio',
      _ => null,
    };

    if (currentType == null) {
      if (!snapshot.exists) return;
      await docRef.set(
        {
          'status': 'resolved',
          'isRead': true,
          'title': 'Stock normalizado',
          'message': 'El producto volvió a un nivel saludable.',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return;
    }

    final keepRead = existing['status'] == 'active' && existing['type'] == currentType
        ? (existing['isRead'] ?? false) as bool
        : false;

    await docRef.set(
      {
        'id': docRef.id,
        'productId': product.id,
        'productName': product.name,
        'type': currentType,
        'title': status.alertTitle,
        'message': status.message,
        'severity': status.severity,
        'currentStock': product.totalStock,
        'minStock': product.minStock,
        'status': 'active',
        'isRead': keepRead,
        'createdAt': snapshot.exists
            ? (existing['createdAt'] ?? FieldValue.serverTimestamp())
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _syncExpiryAlert(String userId, Product product) async {
    final docRef = _collection(userId).doc('${product.id}_expiry');
    final snapshot = await docRef.get();
    final existing = snapshot.data() ?? <String, dynamic>{};

    final expiryType = _resolveExpiryType(product);
    if (expiryType == null) {
      if (!snapshot.exists) return;
      await docRef.set(
        {
          'status': 'resolved',
          'isRead': true,
          'title': 'Sin riesgo de vencimiento',
          'message': 'El producto no presenta vencimiento próximo.',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return;
    }

    final keepRead = existing['status'] == 'active' && existing['type'] == expiryType.type
        ? (existing['isRead'] ?? false) as bool
        : false;

    await docRef.set(
      {
        'id': docRef.id,
        'productId': product.id,
        'productName': product.name,
        'type': expiryType.type,
        'title': expiryType.title,
        'message': expiryType.message,
        'severity': expiryType.severity,
        'currentStock': product.totalStock,
        'minStock': product.minStock,
        'expiryDate': product.expiryDate == null
            ? null
            : Timestamp.fromDate(product.expiryDate!),
        'status': 'active',
        'isRead': keepRead,
        'createdAt': snapshot.exists
            ? (existing['createdAt'] ?? FieldValue.serverTimestamp())
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  _ExpiryAlertPayload? _resolveExpiryType(Product product) {
    if (product.expiryDate == null) return null;
    if (product.isExpired) {
      return const _ExpiryAlertPayload(
        type: 'producto_vencido',
        title: 'Producto vencido',
        message: 'Este producto ya superó su fecha de vencimiento.',
        severity: 'critical',
      );
    }
    if (product.expiresWithin7Days) {
      return const _ExpiryAlertPayload(
        type: 'vence_pronto',
        title: 'Este producto vence pronto',
        message: 'El producto vencerá dentro de los próximos 7 días.',
        severity: 'high',
      );
    }
    if (product.expiresWithin15Days) {
      return const _ExpiryAlertPayload(
        type: 'vencimiento_warning',
        title: 'Vencimiento próximo',
        message: 'El producto vencerá dentro de los próximos 15 días.',
        severity: 'medium',
      );
    }
    return null;
  }
}

class _ExpiryAlertPayload {
  const _ExpiryAlertPayload({
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
  });

  final String type;
  final String title;
  final String message;
  final String severity;
}
