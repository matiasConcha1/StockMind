import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:stockmind/core/services/company_scope_service.dart';
import 'package:stockmind/features/dashboard/data/models/stock_movement.dart';

class StockMovementService {
  StockMovementService({
    FirebaseFirestore? firestore,
    CompanyScopeService? scopeService,
  }) : _scopeService =
            scopeService ?? CompanyScopeService(firestore: firestore);

  final CompanyScopeService _scopeService;

  CollectionReference<Map<String, dynamic>> _collection(String companyId) {
    return _scopeService.companyCollection(companyId, 'stock_movements');
  }

  Stream<List<StockMovement>> watchRecentMovements(
    String companyId, {
    int limit = 20,
  }) {
    debugPrint(
      'StockMovementService.watchRecentMovements: companyId=$companyId limit=$limit',
    );
    return _collection(companyId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(StockMovement.fromFirestore).toList(),
        );
  }

  Stream<List<StockMovement>> watchMovements(String companyId) {
    debugPrint('StockMovementService.watchMovements: companyId=$companyId');
    return _collection(companyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(StockMovement.fromFirestore).toList(),
        );
  }

  DocumentReference<Map<String, dynamic>> createMovementReference(String companyId) {
    return _collection(companyId).doc();
  }
}
