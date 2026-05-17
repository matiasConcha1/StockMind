import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
import 'package:stockmind/features/company/models/company_workspace.dart';

class CurrentCompanyProvider extends ChangeNotifier {
  CurrentCompanyProvider({
    required AuthProvider authProvider,
    FirebaseFirestore? firestore,
  })  : _authProvider = authProvider,
        _firestore = firestore ?? FirebaseFirestore.instance {
    _authProvider.addListener(_handleAuthChanged);
    _handleAuthChanged();
  }

  final AuthProvider _authProvider;
  final FirebaseFirestore _firestore;

  CompanyWorkspace? _company;
  bool _loading = false;
  String? _error;
  Future<void>? _pendingLoad;

  CompanyWorkspace? get company => _company;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get hasCompany => _company != null;
  String? get companyId => _company?.id;
  String get companyName =>
      _company?.companyName.trim().isNotEmpty == true
          ? _company!.companyName.trim()
          : 'Sin empresa';
  String get role => _company?.role ?? (_authProvider.user?.role ?? 'viewer');

  Future<void> refresh() {
    _pendingLoad ??= _load().whenComplete(() {
      _pendingLoad = null;
    });
    return _pendingLoad!;
  }

  void _handleAuthChanged() {
    if (!_authProvider.isAuthenticated) {
      _company = null;
      _loading = false;
      _error = null;
      notifyListeners();
      return;
    }
    unawaited(refresh());
  }

  Future<void> _load() async {
    final user = _authProvider.user;
    if (user == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final userRef = _firestore.collection('users').doc(user.id);
      final userSnapshot = await userRef.get();
      final userData = userSnapshot.data() ?? const <String, dynamic>{};
      final accountType = _normalizeAccountType(
        userData['accountType'] ?? user.accountType,
      );
      var currentCompanyId = (userData['currentCompanyId'] as String?)?.trim();
      if (currentCompanyId == null || currentCompanyId.isEmpty) {
        currentCompanyId = await _ensureWorkspace(
          uid: user.id,
          displayName: user.displayName,
          email: user.email,
          role: user.role,
          accountType: accountType,
        );
      }

      final companyRef = _firestore.collection('companies').doc(currentCompanyId);
      final membershipRef = companyRef.collection('users').doc(user.id);
      final companySnapshot = await companyRef.get();
      final membershipSnapshot = await membershipRef.get();
      if (!companySnapshot.exists || !membershipSnapshot.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'No encontramos la empresa activa del usuario.',
        );
      }
      _company = CompanyWorkspace.fromSnapshots(
        companyDoc: companySnapshot,
        membershipDoc: membershipSnapshot,
      );
      _error = null;
    } catch (error, stackTrace) {
      debugPrint('CurrentCompanyProvider._load error: $error');
      debugPrint('$stackTrace');
      _company = null;
      _error = 'No fue posible cargar la empresa activa.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String> _ensureWorkspace({
    required String uid,
    required String displayName,
    required String email,
    required String role,
    required String accountType,
  }) async {
    final companyId = 'company_$uid';
    final companyRef = _firestore.collection('companies').doc(companyId);
    final companySnapshot = await companyRef.get();
    final userRef = _firestore.collection('users').doc(uid);
    final legacyCompanyProfile = await userRef
        .collection('company_profile')
        .doc('company_profile')
        .get();
    final legacyProfileData = legacyCompanyProfile.data() ?? const <String, dynamic>{};
    final companyName = _resolveCompanyName(
      accountType: accountType,
      displayName: displayName,
      fallbackEmail: email,
      rawCompanyName: legacyProfileData['name'],
    );
    final normalizedRole = _normalizeRole(role);

    await companyRef.set({
      'id': companyId,
      'ownerId': uid,
      'plan': 'trial',
      'companyName': companyName,
      'logoUrl': legacyProfileData['logoUrl'],
      'settings': {
        'defaultMinStock': 5,
        'multiTenantReady': true,
      },
      if (!companySnapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await companyRef.collection('users').doc(uid).set({
      'uid': uid,
      'role': normalizedRole,
      'joinedAt': FieldValue.serverTimestamp(),
      'accountType': accountType,
      'email': email,
      'displayName': displayName,
      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await userRef.set({
      'currentCompanyId': companyId,
      'companyIds': FieldValue.arrayUnion([companyId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _migrateLegacyWorkspace(uid: uid, companyId: companyId);
    return companyId;
  }

  Future<void> _migrateLegacyWorkspace({
    required String uid,
    required String companyId,
  }) async {
    final legacyUserRef = _firestore.collection('users').doc(uid);
    final companyRef = _firestore.collection('companies').doc(companyId);
    for (final collectionName in const [
      'products',
      'locations',
      'location_types',
      'alerts',
      'stock_movements',
      'stock_requests',
      'activity_logs',
      'company_profile',
    ]) {
      final targetSnapshot =
          await companyRef.collection(collectionName).limit(1).get();
      if (targetSnapshot.docs.isNotEmpty) continue;
      final sourceSnapshot =
          await legacyUserRef.collection(collectionName).get();
      if (sourceSnapshot.docs.isEmpty) continue;

      WriteBatch? batch;
      var ops = 0;
      for (final doc in sourceSnapshot.docs) {
        batch ??= _firestore.batch();
        batch.set(companyRef.collection(collectionName).doc(doc.id), doc.data());
        ops++;
        if (ops == 400) {
          await batch.commit();
          batch = null;
          ops = 0;
        }
      }
      if (batch != null && ops > 0) {
        await batch.commit();
      }
    }
  }

  String _normalizeRole(String role) {
    switch (role.trim().toLowerCase()) {
      case 'admin':
      case 'editor':
      case 'operator':
      case 'viewer':
        return role.trim().toLowerCase();
      default:
        return 'viewer';
    }
  }

  String _normalizeAccountType(String value) {
    return value.trim().toLowerCase() == 'business' ? 'business' : 'person';
  }

  String _resolveCompanyName({
    required String accountType,
    required String displayName,
    required String fallbackEmail,
    dynamic rawCompanyName,
  }) {
    final candidate = (rawCompanyName is String ? rawCompanyName : '').trim();
    if (candidate.isNotEmpty) return candidate;
    if (accountType == 'business') {
      return displayName.trim().isNotEmpty
          ? displayName.trim()
          : 'Mi empresa';
    }
    if (displayName.trim().isNotEmpty) {
      return 'Workspace de ${displayName.trim()}';
    }
    final handle = fallbackEmail.split('@').first.trim();
    return handle.isNotEmpty ? 'Workspace de $handle' : 'Workspace personal';
  }

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthChanged);
    super.dispose();
  }
}
