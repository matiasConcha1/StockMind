import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:stockmind/core/services/company_scope_service.dart';

class ActivityLogService {
  ActivityLogService({
    FirebaseFirestore? firestore,
    CompanyScopeService? scopeService,
  }) : _scopeService =
            scopeService ?? CompanyScopeService(firestore: firestore);

  final CompanyScopeService _scopeService;

  Future<void> createLog({
    required String companyId,
    required String action,
    required String entityType,
    required String entityId,
    required String entityName,
    required String description,
  }) async {
    try {
      await _scopeService
          .companyCollection(companyId, 'activity_logs')
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

