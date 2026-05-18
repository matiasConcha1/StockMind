import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:stockmind/features/auth/data/models/app_user.dart';
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
  List<CompanyWorkspace> _companies = const [];
  bool _loading = false;
  String? _error;
  Future<void>? _pendingLoad;

  CompanyWorkspace? get company => _company;
  CompanyWorkspace? get currentCompany => _company;
  List<CompanyWorkspace> get companies => List.unmodifiable(_companies);
  bool get isLoading => _loading;
  String? get error => _error;
  String? get errorMessage => _error;
  bool get hasCompany => _company != null;
  String? get companyId => _company?.id;
  String? get currentCompanyId => _company?.id;
  String get companyName =>
      _company?.companyName.trim().isNotEmpty == true
          ? _company!.companyName.trim()
          : 'Sin espacio';
  String get role =>
      _normalizeRole(_company?.role ?? _authProvider.user?.role ?? 'viewer');
  String get currentRole => role;
  bool get hasAcceptedMembership =>
      _company != null &&
      _company!.status.trim().toLowerCase() == 'accepted';
  bool get canReadCompanyData => hasAcceptedMembership;
  bool get canManageCatalog => canReadCompanyData && _isAnyRole(const [
        'admin',
        'editor',
      ]);
  bool get canManageInventory => canReadCompanyData && _isAnyRole(const [
        'admin',
        'editor',
        'operator',
      ]);
  bool get canManageLocations => canManageCatalog;
  bool get canCreateRequests => canManageInventory;
  bool get canDelete => canReadCompanyData && role == 'admin';
  bool get canExport => canReadCompanyData && role == 'admin';
  bool get canManageUsers => canReadCompanyData && role == 'admin';
  bool get canManageSettings => canReadCompanyData && role == 'admin';
  bool get hasMultipleCompanies => _companies.length > 1;

  Future<void> refresh() {
    final user = _authProvider.user;
    if (user == null) {
      _resetState();
      return Future.value();
    }
    return initializeForUser(user);
  }

  Future<void> initializeForUser(AppUser user) {
    _pendingLoad ??= _loadForUser(user).whenComplete(() {
      _pendingLoad = null;
    });
    return _pendingLoad!;
  }

  void _handleAuthChanged() {
    if (_authProvider.isLoading && !_authProvider.initialized) {
      _loading = true;
      notifyListeners();
      return;
    }

    final user = _authProvider.user;
    if (user == null) {
      _resetState();
      return;
    }

    unawaited(initializeForUser(user));
  }

  Future<void> _loadForUser(AppUser user) async {
    _loading = true;
    _error = null;
    notifyListeners();
    _debug(
      'initializeForUser: uid=${user.id} email=${user.email} accountType=${user.accountType}',
    );

    try {
      final userRef = _firestore.collection('users').doc(user.id);
      final userSnapshot = await userRef.get();
      final userData = userSnapshot.data() ?? const <String, dynamic>{};
      final accountType = _normalizeAccountType(
        userData['accountType'] ?? user.accountType,
      );
      final preferredCompanyId =
          (userData['currentCompanyId'] as String?)?.trim();

      var memberships = await _loadAcceptedMemberships(user.id);
      _debug('initializeForUser: accepted memberships=${memberships.length}');

      if (memberships.isEmpty) {
        _debug('initializeForUser: no memberships found, bootstrapping workspace');
        await _ensureWorkspace(
          uid: user.id,
          displayName: user.displayName,
          email: user.email,
          role: user.role,
          accountType: accountType,
        );
        memberships = await _loadAcceptedMemberships(user.id);
        _debug(
          'initializeForUser: memberships after bootstrap=${memberships.length}',
        );
      }

      memberships = await _repairOwnedWorkspaceMemberships(
        userId: user.id,
        email: user.email,
        displayName: user.displayName,
        memberships: memberships,
      );
      _debug(
        'initializeForUser: memberships after repair=${memberships.length}',
      );

      if (memberships.isEmpty) {
        _company = null;
        _companies = const [];
        _error =
            'Configura tu espacio de trabajo para comenzar.';
        return;
      }

      memberships.sort(
        (a, b) => a.companyName.toLowerCase().compareTo(
              b.companyName.toLowerCase(),
            ),
      );

      final selected = _selectCurrentCompany(
        memberships,
        preferredCompanyId: preferredCompanyId,
      );
      _companies = memberships;
      _company = selected;
      _error = null;

      final companyIds = memberships.map((item) => item.id).toList();
      if (preferredCompanyId != selected.id ||
          !_sameIdSet(
            companyIds,
            ((userData['companyIds'] as List?) ?? const [])
                .map((item) => item.toString())
                .toList(),
          )) {
        await userRef.set({
          'currentCompanyId': selected.id,
          'companyIds': companyIds,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      _debug(
        'initializeForUser: selected companyId=${selected.id} role=${selected.role}',
      );
    } catch (error, stackTrace) {
      _debug('initializeForUser error: $error');
      _debug('$stackTrace');
      _company = null;
      _companies = const [];
      _error = error.toString().contains('permission-denied')
          ? 'No tienes permisos para abrir este espacio de trabajo.'
          : 'No fue posible cargar el espacio de trabajo activo.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<List<CompanyWorkspace>> _loadAcceptedMemberships(String userId) async {
    final query = await _firestore
        .collectionGroup('users')
        .where('uid', isEqualTo: userId)
        .where('status', isEqualTo: 'accepted')
        .get();

    final items = <CompanyWorkspace>[];
    for (final membershipSnapshot in query.docs) {
      final pathSegments = membershipSnapshot.reference.path.split('/');
      if (pathSegments.length != 4 || pathSegments.first != 'companies') {
        continue;
      }
      final membershipData =
          membershipSnapshot.data();
      if ((membershipData['isActive'] ?? true) != true) {
        continue;
      }
      final companyId = pathSegments[1];
      final companySnapshot =
          await _firestore.collection('companies').doc(companyId).get();
      if (!companySnapshot.exists) {
        continue;
      }
      items.add(
        CompanyWorkspace.fromSnapshots(
          companyDoc: companySnapshot,
          membershipDoc: membershipSnapshot,
        ),
      );
    }
    return items;
  }

  CompanyWorkspace _selectCurrentCompany(
    List<CompanyWorkspace> memberships, {
    required String? preferredCompanyId,
  }) {
    if (preferredCompanyId != null && preferredCompanyId.isNotEmpty) {
      for (final item in memberships) {
        if (item.id == preferredCompanyId) {
          return item;
        }
      }
    }
    return memberships.first;
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
    final legacyProfileData =
        legacyCompanyProfile.data() ?? const <String, dynamic>{};
    final companyName = _resolveCompanyName(
      accountType: accountType,
      displayName: displayName,
      fallbackEmail: email,
      rawCompanyName: legacyProfileData['name'],
    );
    final normalizedRole = _roleForWorkspaceOwner(
      role: role,
      accountType: accountType,
      workspaceType: accountType == 'person' ? 'personal' : 'business',
    );

    await companyRef.set({
      'id': companyId,
      'ownerId': uid,
      'plan': 'trial',
      'companyName': companyName,
      'logoUrl': legacyProfileData['logoUrl'],
      'settings': {
        'defaultMinStock': 5,
        'multiTenantReady': true,
        'workspaceType': accountType == 'person' ? 'personal' : 'business',
      },
      if (!companySnapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await companyRef.collection('users').doc(uid).set({
      'uid': uid,
      'role': normalizedRole,
      'joinedAt': FieldValue.serverTimestamp(),
      'invitedBy': uid,
      'status': 'accepted',
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

  Future<void> switchCompany(String companyId) async {
    final userId = _authProvider.user?.id;
    if (userId == null) return;
    if (!_companies.any((item) => item.id == companyId)) return;
    await _firestore.collection('users').doc(userId).set({
      'currentCompanyId': companyId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await refresh();
  }

  Future<String> createCompany({
    required String companyName,
    String? industry,
    String workspaceType = 'business',
  }) async {
    final authUser = _authProvider.user;
    if (authUser == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Debes iniciar sesión para crear un espacio de trabajo.',
      );
    }

    final normalizedCompanyName = companyName.trim();
    if (normalizedCompanyName.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-argument',
        message: 'Ingresa un nombre válido para el espacio de trabajo.',
      );
    }

    final companyRef = _firestore.collection('companies').doc();
    final userRef = _firestore.collection('users').doc(authUser.id);
    final normalizedIndustry = (industry ?? '').trim();
    final normalizedWorkspaceType =
        _normalizeWorkspaceType(workspaceType, authUser.accountType);
    final accountType = _normalizeAccountType(authUser.accountType);
    final ownerRole = _roleForWorkspaceOwner(
      role: authUser.role,
      accountType: accountType,
      workspaceType: normalizedWorkspaceType,
    );
    final batch = _firestore.batch();

    batch.set(companyRef, {
      'id': companyRef.id,
      'ownerId': authUser.id,
      'plan': 'free',
      'companyName': normalizedCompanyName,
      'logoUrl': null,
      'settings': {
        'defaultMinStock': 5,
        'multiTenantReady': true,
        'workspaceType': normalizedWorkspaceType,
        if (normalizedIndustry.isNotEmpty) 'industry': normalizedIndustry,
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(companyRef.collection('users').doc(authUser.id), {
      'uid': authUser.id,
      'role': ownerRole,
      'joinedAt': FieldValue.serverTimestamp(),
      'invitedBy': authUser.id,
      'status': 'accepted',
      'accountType': accountType,
      'email': authUser.email,
      'displayName': authUser.displayName,
      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(companyRef.collection('company_profile').doc('company_profile'), {
      'id': 'company_profile',
      'name': normalizedCompanyName,
      'industry': normalizedIndustry,
      'phone': '',
      'email': authUser.email,
      'address': '',
      'website': '',
      'logoUrl': null,
      'createdBy': authUser.id,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(userRef, {
      'companyIds': FieldValue.arrayUnion([companyRef.id]),
      'currentCompanyId': companyRef.id,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    try {
      await batch.commit();
      await refresh();
      return companyRef.id;
    } on FirebaseException catch (error, stackTrace) {
      _debug('createCompany FirebaseException: ${error.code} ${error.message}');
      _debug('$stackTrace');
      throw _WorkspaceOperationException(_friendlyWorkspaceError(error));
    } catch (error, stackTrace) {
      _debug('createCompany error: $error');
      _debug('$stackTrace');
      throw const _WorkspaceOperationException(
        'No se pudo crear el espacio de trabajo. Verifica tus permisos o intenta nuevamente.',
      );
    }
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
      final sourceSnapshot = await legacyUserRef.collection(collectionName).get();
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

  Future<List<CompanyWorkspace>> _repairOwnedWorkspaceMemberships({
    required String userId,
    required String email,
    required String displayName,
    required List<CompanyWorkspace> memberships,
  }) async {
    var repaired = false;

    for (final item in memberships) {
      if (item.ownerId != userId) continue;
      final expectedRole = _roleForWorkspaceOwner(
        role: item.role,
        accountType: item.accountType,
        workspaceType: item.workspaceType,
      );
      if (item.role == expectedRole && item.status == 'accepted') continue;

      await _firestore
          .collection('companies')
          .doc(item.id)
          .collection('users')
          .doc(userId)
          .set({
        'uid': userId,
        'role': expectedRole,
        'status': 'accepted',
        'email': email,
        'displayName': displayName,
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      repaired = true;
      _debug(
        'repairOwnedWorkspaceMemberships: repaired companyId=${item.id} role=$expectedRole',
      );
    }

    if (!repaired) {
      return memberships;
    }
    return _loadAcceptedMemberships(userId);
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

  String _roleForWorkspaceOwner({
    required String role,
    required String accountType,
    required String workspaceType,
  }) {
    final normalizedWorkspaceType =
        _normalizeWorkspaceType(workspaceType, accountType);
    final normalizedAccountType = _normalizeAccountType(accountType);
    if (normalizedWorkspaceType == 'personal' ||
        normalizedAccountType == 'person') {
      return 'admin';
    }
    final normalizedRole = _normalizeRole(role);
    return normalizedRole == 'viewer' ? 'admin' : normalizedRole;
  }

  bool _isAnyRole(List<String> allowedRoles) {
    return allowedRoles.contains(role);
  }

  String _normalizeWorkspaceType(String? value, String accountType) {
    final normalized = (value ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'personal':
      case 'person':
        return 'personal';
      case 'company':
      case 'empresa':
        return 'company';
      case 'business':
      case 'negocio':
        return 'business';
      default:
        return accountType.trim().toLowerCase() == 'person'
            ? 'personal'
            : 'business';
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
      return displayName.trim().isNotEmpty ? displayName.trim() : 'Mi empresa';
    }
    if (displayName.trim().isNotEmpty) {
      return 'Espacio de ${displayName.trim()}';
    }
    final handle = fallbackEmail.split('@').first.trim();
    return handle.isNotEmpty ? 'Espacio de $handle' : 'Espacio personal';
  }

  bool _sameIdSet(List<String> left, List<String> right) {
    final leftSet = left.map((item) => item.trim()).where((item) => item.isNotEmpty).toSet();
    final rightSet = right.map((item) => item.trim()).where((item) => item.isNotEmpty).toSet();
    return leftSet.length == rightSet.length && leftSet.containsAll(rightSet);
  }

  void _resetState() {
    _company = null;
    _companies = const [];
    _loading = false;
    _error = null;
    notifyListeners();
  }

  void _debug(String message) {
    if (kDebugMode) {
      debugPrint('CurrentCompanyProvider: $message');
    }
  }

  String _friendlyWorkspaceError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'No se pudo crear el espacio de trabajo. Verifica tus permisos o intenta nuevamente.';
      case 'unavailable':
        return 'Firestore no está disponible en este momento. Intenta nuevamente.';
      case 'failed-precondition':
        return 'Falta configuración en Firestore para crear el espacio de trabajo.';
      default:
        final message = error.message?.trim() ?? '';
        return message.isNotEmpty
            ? message
            : 'No se pudo crear el espacio de trabajo. Verifica tus permisos o intenta nuevamente.';
    }
  }

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthChanged);
    super.dispose();
  }
}

class _WorkspaceOperationException implements Exception {
  const _WorkspaceOperationException(this.message);

  final String message;

  @override
  String toString() => message;
}
