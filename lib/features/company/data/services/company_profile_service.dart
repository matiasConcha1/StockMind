import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:stockmind/features/company/models/company_profile.dart';

class CompanyProfileService {
  CompanyProfileService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _docRef(String companyId) =>
      _firestore
          .collection('companies')
          .doc(companyId)
          .collection('company_profile')
          .doc('company_profile');

  DocumentReference<Map<String, dynamic>> get _legacyDocRef =>
      _firestore.collection('app_config').doc('company_profile');

  Stream<CompanyProfile?> watchProfile(String companyId) async* {
    yield await getProfile(companyId);
    yield* _docRef(companyId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return CompanyProfile.fromFirestore(snapshot);
    });
  }

  Future<CompanyProfile?> getProfile(String companyId) async {
    final snapshot = await _docRef(companyId).get();
    if (snapshot.exists) {
      return CompanyProfile.fromFirestore(snapshot);
    }
    final legacySnapshot = await _legacyDocRef.get();
    if (!legacySnapshot.exists) return null;
    return CompanyProfile.fromFirestore(legacySnapshot);
  }

  Future<void> saveProfile(String companyId, CompanyProfile profile) async {
    final existing = await _docRef(companyId).get();
    debugPrint(
      'CompanyProfileService.saveProfile: exists=${existing.exists} name=${profile.name}',
    );
    await _docRef(companyId).set(
      profile.toMap(isNew: !existing.exists),
      SetOptions(merge: true),
    );
  }
}
