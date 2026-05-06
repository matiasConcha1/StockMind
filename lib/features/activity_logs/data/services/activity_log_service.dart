import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ActivityLogService {
  ActivityLogService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> createLog({
    required String userId,
    required String action,
    required String entityType,
    required String entityId,
    required String entityName,
    required String description,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('activity_logs')
          .add({
        'action': action,
        'entityType': entityType,
        'entityId': entityId,
        'entityName': entityName,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (error, stackTrace) {
      debugPrint('ActivityLogService.createLog error: $error');
      debugPrint('$stackTrace');
    }
  }
}

