import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyScopeService {
  CompanyScopeService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> rootUsers() {
    return _firestore.collection('users');
  }

  DocumentReference<Map<String, dynamic>> companyDoc(String companyId) {
    return _firestore.collection('companies').doc(companyId);
  }

  CollectionReference<Map<String, dynamic>> companyCollection(
    String companyId,
    String collectionName,
  ) {
    return companyDoc(companyId).collection(collectionName);
  }

  CollectionReference<Map<String, dynamic>> legacyUserCollection(
    String userId,
    String collectionName,
  ) {
    return rootUsers().doc(userId).collection(collectionName);
  }
}
