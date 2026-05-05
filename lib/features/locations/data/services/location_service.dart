import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:stockmind/features/locations/models/inventory_location.dart';

class LocationService {
  LocationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore.collection('users').doc(userId).collection('locations');
  }

  String createLocationId(String userId) => _collection(userId).doc().id;

  CollectionReference<Map<String, dynamic>> _typesCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('location_types');
  }

  Stream<List<InventoryLocation>> watchLocations(String userId) {
    debugPrint('LocationService.watchLocations: userId=$userId');
    return _collection(userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(InventoryLocation.fromFirestore).toList(),
        );
  }

  Future<void> createLocation(String userId, InventoryLocation location) async {
    final docRef = location.id.isEmpty
        ? _collection(userId).doc()
        : _collection(userId).doc(location.id);
    final item = location.copyWith(id: docRef.id);
    debugPrint(
      'LocationService.createLocation: userId=$userId locationId=${docRef.id}',
    );
    await docRef.set(item.toCreateMap());
  }

  Future<void> updateLocation(String userId, InventoryLocation location) async {
    debugPrint(
      'LocationService.updateLocation: userId=$userId locationId=${location.id}',
    );
    await _collection(userId).doc(location.id).update(location.toUpdateMap());
  }

  Future<void> deleteLocation(String userId, String locationId) async {
    debugPrint(
      'LocationService.deleteLocation: userId=$userId locationId=$locationId',
    );
    await _collection(userId).doc(locationId).delete();
  }

  Stream<List<String>> watchLocationTypes(String userId) {
    debugPrint('LocationService.watchLocationTypes: userId=$userId');
    return _typesCollection(userId)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => (doc.data()['name'] ?? '') as String)
              .where((name) => name.trim().isNotEmpty)
              .toList(),
        );
  }

  Future<void> saveLocationTypeIfMissing(String userId, String type) async {
    final normalized = type.trim();
    if (normalized.isEmpty) return;

    final docId = _typeDocumentId(normalized);
    final docRef = _typesCollection(userId).doc(docId);
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
