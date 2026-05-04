import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:stockmind/features/dashboard/data/models/stock_movement.dart';

class StockMovementService {
  StockMovementService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('stock_movements');
  }

  Stream<List<StockMovement>> watchRecentMovements(
    String userId, {
    int limit = 8,
  }) {
    debugPrint(
      'StockMovementService.watchRecentMovements: userId=$userId limit=$limit',
    );
    return _collection(userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(StockMovement.fromFirestore).toList(),
        );
  }

  DocumentReference<Map<String, dynamic>> createMovementReference(String userId) {
    return _collection(userId).doc();
  }
}
