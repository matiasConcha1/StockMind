import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:stockmind/features/company/models/company_profile.dart';

class CompanyProfileService {
  CompanyProfileService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _docRef =>
      _firestore.collection('app_config').doc('company_profile');

  Stream<CompanyProfile?> watchProfile() {
    return _docRef.snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return CompanyProfile.fromFirestore(snapshot);
    });
  }

  Future<CompanyProfile?> getProfile() async {
    final snapshot = await _docRef.get();
    if (!snapshot.exists) return null;
    return CompanyProfile.fromFirestore(snapshot);
  }

  Future<void> saveProfile(CompanyProfile profile) async {
    final existing = await _docRef.get();
    debugPrint(
      'CompanyProfileService.saveProfile: exists=${existing.exists} name=${profile.name}',
    );
    await _docRef.set(
      profile.toMap(isNew: !existing.exists),
      SetOptions(merge: true),
    );
  }
}
