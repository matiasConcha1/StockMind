import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:stockmind/core/services/company_scope_service.dart';
import 'package:stockmind/features/locations/models/inventory_location.dart';

class LocationService {
  LocationService({
    FirebaseFirestore? firestore,
    CompanyScopeService? scopeService,
  }) : _scopeService =
            scopeService ?? CompanyScopeService(firestore: firestore);

  final CompanyScopeService _scopeService;

  CollectionReference<Map<String, dynamic>> _collection(String companyId) {
    return _scopeService.companyCollection(companyId, 'locations');
  }

  String createLocationId(String companyId) => _collection(companyId).doc().id;

  CollectionReference<Map<String, dynamic>> _typesCollection(String companyId) {
    return _scopeService.companyCollection(companyId, 'location_types');
  }

  Stream<List<InventoryLocation>> watchLocations(String companyId) {
    debugPrint('LocationService.watchLocations: companyId=$companyId');
    return _collection(companyId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(InventoryLocation.fromFirestore).toList(),
        );
  }

  Future<void> createLocation(String companyId, InventoryLocation location) async {
    final docRef = location.id.isEmpty
        ? _collection(companyId).doc()
        : _collection(companyId).doc(location.id);
    final item = location.copyWith(id: docRef.id);
    debugPrint(
      'LocationService.createLocation: companyId=$companyId locationId=${docRef.id}',
    );
    await docRef.set(item.toCreateMap());
  }

  Future<void> updateLocation(String companyId, InventoryLocation location) async {
    debugPrint(
      'LocationService.updateLocation: companyId=$companyId locationId=${location.id}',
    );
    await _collection(companyId).doc(location.id).update(location.toUpdateMap());
  }

  Future<void> deleteLocation(String companyId, String locationId) async {
    debugPrint(
      'LocationService.deleteLocation: companyId=$companyId locationId=$locationId',
    );
    await _collection(companyId).doc(locationId).delete();
  }

  Stream<List<String>> watchLocationTypes(String companyId) {
    debugPrint('LocationService.watchLocationTypes: companyId=$companyId');
    return _typesCollection(companyId)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => (doc.data()['name'] ?? '') as String)
              .where((name) => name.trim().isNotEmpty)
              .toList(),
        );
  }

  Future<void> saveLocationTypeIfMissing(String companyId, String type) async {
    final normalized = type.trim();
    if (normalized.isEmpty) return;

    final docId = _typeDocumentId(normalized);
    final docRef = _typesCollection(companyId).doc(docId);
    final snapshot = await docRef.get();
    if (snapshot.exists) return;

    await docRef.set({
      'id': docId,
      'name': normalized,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  String _typeDocumentId(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('/', '-')
        .replaceAll('\\', '-')
        .replaceAll(RegExp(r'\s+'), '-');
  }
}
