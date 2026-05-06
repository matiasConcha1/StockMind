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
    await _syncLowStockAlert(userId, product);
    await _syncExpiryAlerts(userId, product);
    await _resolveLegacyAlerts(userId, product.id);
  }

  Future<void> syncAllProductAlerts(
    String userId,
    Iterable<Product> products,
  ) async {
    for (final product in products) {
      await syncProductAlerts(userId, product);
    }
  }

  Future<void> deleteAlertsForProduct(String userId, String productId) async {
    final batch = _firestore.batch();
    for (final suffix in const [
      'low_stock',
      'expiring_soon',
      'expired',
      'stock',
      'expiry',
    ]) {
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

  Future<StockAlert?> getAlertById(String userId, String alertId) async {
    final snapshot = await _collection(userId).doc(alertId).get();
    if (!snapshot.exists) return null;
    return StockAlert.fromFirestore(snapshot);
  }

  Future<void> resolveAlert(
    String userId,
    String alertId, {
    required String resolvedBy,
  }) async {
    await _collection(userId).doc(alertId).set(
      {
        'status': 'resolved',
        'isRead': true,
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolvedBy': resolvedBy,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _syncLowStockAlert(String userId, Product product) async {
    final shouldBeActive = product.totalStock <= 5;
    final docRef = _collection(userId).doc('${product.id}_low_stock');
    final snapshot = await docRef.get();
    final existing = snapshot.data() ?? const <String, dynamic>{};

    if (!shouldBeActive) {
      await _resolveIfNeeded(
        docRef: docRef,
        snapshot: snapshot,
        title: 'Stock normalizado',
        message: 'El producto volvió a un nivel saludable de inventario.',
      );
      return;
    }

    final severity = product.totalStock <= 0 ? 'high' : 'medium';
    final title =
        product.totalStock <= 0 ? 'Producto sin stock' : 'Stock bajo';
    final message = product.totalStock <= 0
        ? 'Este producto no tiene unidades disponibles.'
        : 'Este producto tiene 5 unidades o menos y requiere reposición.';

    await docRef.set(
      {
        'id': docRef.id,
        'productId': product.id,
        'productName': product.name,
        'type': 'low_stock',
        'title': title,
        'message': message,
        'severity': severity,
        'currentStock': product.totalStock,
        'minStock': product.minStock,
        'status': 'active',
        'isRead': _keepRead(existing, 'low_stock'),
        'createdAt': snapshot.exists
            ? (existing['createdAt'] ?? FieldValue.serverTimestamp())
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'resolvedAt': null,
        'resolvedBy': null,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _syncExpiryAlerts(String userId, Product product) async {
    final expiredRef = _collection(userId).doc('${product.id}_expired');
    final expiringSoonRef = _collection(userId).doc('${product.id}_expiring_soon');
    final expiredSnapshot = await expiredRef.get();
    final expiringSoonSnapshot = await expiringSoonRef.get();
    final expiredExisting = expiredSnapshot.data() ?? const <String, dynamic>{};
    final expiringExisting =
        expiringSoonSnapshot.data() ?? const <String, dynamic>{};

    if (product.expiryDate == null) {
      await _resolveIfNeeded(
        docRef: expiredRef,
        snapshot: expiredSnapshot,
        title: 'Sin riesgo de vencimiento',
        message: 'El producto no presenta vencimiento vencido.',
      );
      await _resolveIfNeeded(
        docRef: expiringSoonRef,
        snapshot: expiringSoonSnapshot,
        title: 'Sin riesgo de vencimiento',
        message: 'El producto no presenta vencimiento próximo.',
      );
      return;
    }

    if (product.isExpired) {
      await expiredRef.set(
        {
          'id': expiredRef.id,
          'productId': product.id,
          'productName': product.name,
          'type': 'expired',
          'title': 'Producto vencido',
          'message': 'Este producto ya superó su fecha de vencimiento.',
          'severity': 'high',
          'currentStock': product.totalStock,
          'minStock': product.minStock,
          'expirationDate': Timestamp.fromDate(product.expiryDate!),
          'expiryDate': Timestamp.fromDate(product.expiryDate!),
          'status': 'active',
          'isRead': _keepRead(expiredExisting, 'expired'),
          'createdAt': expiredSnapshot.exists
              ? (expiredExisting['createdAt'] ?? FieldValue.serverTimestamp())
              : FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'resolvedAt': null,
          'resolvedBy': null,
        },
        SetOptions(merge: true),
      );
      await _resolveIfNeeded(
        docRef: expiringSoonRef,
        snapshot: expiringSoonSnapshot,
        title: 'Vencimiento superado',
        message: 'El producto ya no está en la ventana de próximo vencimiento.',
      );
      return;
    }

    if (product.expiresWithin7Days) {
      await expiringSoonRef.set(
        {
          'id': expiringSoonRef.id,
          'productId': product.id,
          'productName': product.name,
          'type': 'expiring_soon',
          'title': 'Este producto vence pronto',
          'message': 'El producto vencerá dentro de los próximos 7 días.',
          'severity': 'medium',
          'currentStock': product.totalStock,
          'minStock': product.minStock,
          'expirationDate': Timestamp.fromDate(product.expiryDate!),
          'expiryDate': Timestamp.fromDate(product.expiryDate!),
          'status': 'active',
          'isRead': _keepRead(expiringExisting, 'expiring_soon'),
          'createdAt': expiringSoonSnapshot.exists
              ? (expiringExisting['createdAt'] ??
                  FieldValue.serverTimestamp())
              : FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'resolvedAt': null,
          'resolvedBy': null,
        },
        SetOptions(merge: true),
      );
      await _resolveIfNeeded(
        docRef: expiredRef,
        snapshot: expiredSnapshot,
        title: 'Producto vigente',
        message: 'El producto ya no figura como vencido.',
      );
      return;
    }

    await _resolveIfNeeded(
      docRef: expiredRef,
      snapshot: expiredSnapshot,
      title: 'Producto vigente',
      message: 'El producto ya no figura como vencido.',
    );
    await _resolveIfNeeded(
      docRef: expiringSoonRef,
      snapshot: expiringSoonSnapshot,
      title: 'Sin riesgo de vencimiento',
      message: 'El producto ya no está próximo a vencer.',
    );
  }

  Future<void> _resolveLegacyAlerts(String userId, String productId) async {
    for (final suffix in const ['stock', 'expiry']) {
      final ref = _collection(userId).doc('${productId}_$suffix');
      final snapshot = await ref.get();
      if (!snapshot.exists) continue;
      await _resolveIfNeeded(
        docRef: ref,
        snapshot: snapshot,
        title: 'Alerta migrada',
        message: 'La alerta quedó resuelta por la nueva lógica del sistema.',
      );
    }
  }

  bool _keepRead(Map<String, dynamic> existing, String type) {
    return existing['status'] == 'active' && existing['type'] == type
        ? (existing['isRead'] ?? false) as bool
        : false;
  }

  Future<void> _resolveIfNeeded({
    required DocumentReference<Map<String, dynamic>> docRef,
    required DocumentSnapshot<Map<String, dynamic>> snapshot,
    required String title,
    required String message,
  }) async {
    if (!snapshot.exists) return;
    final data = snapshot.data() ?? const <String, dynamic>{};
    if (data['status'] == 'resolved') return;
    await docRef.set(
      {
        'status': 'resolved',
        'isRead': true,
        'title': title,
        'message': message,
        'resolvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
