import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stockmind/features/activity_logs/data/services/activity_log_service.dart';
import 'package:stockmind/features/dashboard/data/models/stock_movement.dart';
import 'package:stockmind/features/products/models/product.dart';
import 'package:stockmind/features/replenishment/models/stock_request.dart';

class StockRequestService {
  StockRequestService({
    FirebaseFirestore? firestore,
    ActivityLogService? activityLogService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _activityLogService = activityLogService ?? ActivityLogService();

  final FirebaseFirestore _firestore;
  final ActivityLogService _activityLogService;

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore.collection('users').doc(userId).collection('stock_requests');
  }

  CollectionReference<Map<String, dynamic>> _products(String userId) {
    return _firestore.collection('users').doc(userId).collection('products');
  }

  CollectionReference<Map<String, dynamic>> _movements(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('stock_movements');
  }

  String createRequestId(String userId) => _collection(userId).doc().id;

  Stream<List<StockRequest>> watchRequests(String userId) {
    return _collection(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(StockRequest.fromFirestore).toList());
  }

  Future<void> createRequest(String userId, StockRequest request) async {
    await _assertNoPendingDuplicate(
      userId: userId,
      productId: request.productId,
      locationId: request.locationId,
    );
    final doc = request.id.isEmpty
        ? _collection(userId).doc()
        : _collection(userId).doc(request.id);
    await doc.set(request.copyWith(id: doc.id).toCreateMap());
    await _activityLogService.createLog(
      userId: userId,
      action: 'create_stock_request',
      entityType: 'stock_request',
      entityId: doc.id,
      entityName: request.productName,
      description:
          'Se creó una solicitud de reposición para ${request.productName} en ${request.locationName}.',
    );
  }

  Future<void> approveRequest({
    required String userId,
    required StockRequest request,
  }) async {
    if (!request.isPending) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'failed-precondition',
        message: 'Solo las solicitudes pendientes pueden aprobarse.',
      );
    }
    await _collection(userId).doc(request.id).update({
      'status': 'approved',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _activityLogService.createLog(
      userId: userId,
      action: 'approve_stock_request',
      entityType: 'stock_request',
      entityId: request.id,
      entityName: request.productName,
      description:
          'Se aprobó la solicitud de reposición de ${request.productName}.',
    );
  }

  Future<void> cancelRequest({
    required String userId,
    required StockRequest request,
  }) async {
    if (request.isCompleted || request.isCancelled) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'failed-precondition',
        message: 'La solicitud ya no puede cancelarse.',
      );
    }
    await _collection(userId).doc(request.id).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _activityLogService.createLog(
      userId: userId,
      action: 'cancel_stock_request',
      entityType: 'stock_request',
      entityId: request.id,
      entityName: request.productName,
      description:
          'Se canceló la solicitud de reposición de ${request.productName}.',
    );
  }

  Future<void> completeRequest({
    required String userId,
    required StockRequest request,
    required String completedByUserId,
    required String completedByUserName,
  }) async {
    final requestRef = _collection(userId).doc(request.id);
    final productRef = _products(userId).doc(request.productId);
    final movementRef = _movements(userId).doc();

    await _firestore.runTransaction((transaction) async {
      final requestSnapshot = await transaction.get(requestRef);
      if (!requestSnapshot.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'No encontramos la solicitud de reposición.',
        );
      }
      final currentRequest = StockRequest.fromFirestore(requestSnapshot);
      if (currentRequest.isCompleted) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'failed-precondition',
          message: 'La solicitud ya fue completada.',
        );
      }
      if (currentRequest.isCancelled) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'failed-precondition',
          message: 'La solicitud fue cancelada y no puede completarse.',
        );
      }

      final productSnapshot = await transaction.get(productRef);
      if (!productSnapshot.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'No encontramos el producto asociado a la solicitud.',
        );
      }
      final product = Product.fromFirestore(productSnapshot);
      if (product.isArchived) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'failed-precondition',
          message: 'No puedes reponer un producto archivado.',
        );
      }

      final previousLocation =
          product.locationQuantities[currentRequest.locationId]?.quantity ?? 0;
      final newLocation = previousLocation + currentRequest.requestedQuantity;
      final previousStock = product.totalStock;
      final newStock = previousStock + currentRequest.requestedQuantity;
      final updatedLocations =
          Map<String, ProductLocationQuantity>.from(product.locationQuantities);
      updatedLocations[currentRequest.locationId] = ProductLocationQuantity(
        locationId: currentRequest.locationId,
        locationName: currentRequest.locationName,
        quantity: newLocation,
      );
      final updatedProduct = product.copyWith(
        totalStock: newStock,
        locationQuantities: updatedLocations,
        updatedAt: DateTime.now(),
      );

      transaction.update(productRef, updatedProduct.toUpdateMap());
      transaction.update(requestRef, {
        'status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
        'completedAt': FieldValue.serverTimestamp(),
      });
      final movement = StockMovement(
        id: movementRef.id,
        productId: product.id,
        productName: product.name,
        barcode: product.barcode,
        type: 'entry',
        quantity: currentRequest.requestedQuantity,
        previousStock: previousStock,
        newStock: newStock,
        reason: 'Reposición completada',
        locationId: currentRequest.locationId,
        locationName: currentRequest.locationName,
        previousQuantityInLocation: previousLocation,
        newQuantityInLocation: newLocation,
        previousTotalStock: previousStock,
        newTotalStock: newStock,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: completedByUserId,
        userName: completedByUserName,
      );
      transaction.set(movementRef, movement.toMap());
    });

    await _activityLogService.createLog(
      userId: userId,
      action: 'complete_stock_request',
      entityType: 'stock_request',
      entityId: request.id,
      entityName: request.productName,
      description:
          'Se completó la solicitud de reposición de ${request.productName} en ${request.locationName}.',
    );
  }

  Future<void> _assertNoPendingDuplicate({
    required String userId,
    required String productId,
    required String locationId,
  }) async {
    final snapshot = await _collection(userId)
        .where('productId', isEqualTo: productId)
        .where('locationId', isEqualTo: locationId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'already-exists',
        message:
            'Ya existe una solicitud pendiente para este producto en esa ubicación.',
      );
    }
  }
}
