import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:stockmind/features/auth/data/models/app_user.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
import 'package:stockmind/features/company/models/company_invitation.dart';
import 'package:stockmind/features/company/providers/current_company_provider.dart';

class UserProvider extends ChangeNotifier {
  UserProvider({
    required AuthProvider authProvider,
    required CurrentCompanyProvider currentCompanyProvider,
    FirebaseFirestore? firestore,
  })  : _authProvider = authProvider,
        _currentCompanyProvider = currentCompanyProvider,
        _firestore = firestore ?? FirebaseFirestore.instance {
    _authProvider.addListener(_handleAuthChanged);
    _currentCompanyProvider.addListener(_handleAuthChanged);
    _handleAuthChanged();
  }

  final AuthProvider _authProvider;
  final CurrentCompanyProvider _currentCompanyProvider;
  final FirebaseFirestore _firestore;

  AppUser? _currentUser;
  bool _loading = false;
  String? _error;
  Future<void>? _pendingLoad;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _pendingInvitesSubscription;
  List<CompanyInvitation> _pendingInvitations = const [];

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isOperator => _currentUser?.isOperator ?? false;
  bool get isEditor => _currentUser?.isEditor ?? false;
  bool get isViewer => _currentUser?.isViewer ?? false;
  bool get requiresCompanyProfile => _currentUser?.requiresCompanyProfile ?? false;
  bool get canViewInventory => _currentUser?.canViewInventory ?? false;
  bool get canManageCatalog => _currentUser?.canManageCatalog ?? false;
  bool get canManageInventory => _currentUser?.canManageInventory ?? false;
  bool get canManageLocations => _currentUser?.canManageLocations ?? false;
  bool get canResolveAlerts => _currentUser?.canResolveAlerts ?? false;
  bool get canCreateRequests => _currentUser?.canCreateRequests ?? false;
  bool get canEdit => _currentUser?.canEdit ?? false;
  bool get canDelete => _currentUser?.canDelete ?? false;
  bool get canExport => _currentUser?.canExport ?? false;
  bool get canManageUsers => _currentUser?.canManageUsers ?? false;
  bool get canManageSettings => _currentUser?.canManageSettings ?? false;
  bool get canApproveRequests => _currentUser?.canApproveRequests ?? false;
  bool get hasCompletedOnboarding =>
      _currentUser?.hasCompletedOnboarding ?? false;
  List<CompanyInvitation> get pendingInvitations =>
      List.unmodifiable(_pendingInvitations);
  bool get hasPendingInvitations => _pendingInvitations.isNotEmpty;

  Future<void> loadCurrentUser() {
    _pendingLoad ??= _loadCurrentUserInternal().whenComplete(() {
      _pendingLoad = null;
    });
    return _pendingLoad!;
  }

  Future<void> _loadCurrentUserInternal() async {
    final authUser = _authProvider.user;
    if (authUser == null) {
      clear();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final docRef = _firestore.collection('users').doc(authUser.id);
      final snapshot = await docRef.get();
      final existingData = snapshot.data() ?? const <String, dynamic>{};
      final role = await _resolveUserRole(
        uid: authUser.id,
        exists: snapshot.exists,
        rawRole: existingData['role'],
      );

      final payload = <String, dynamic>{
        'uid': authUser.id,
        'email': authUser.email,
        'name': authUser.displayName,
        'photoUrl': authUser.photoUrl,
        'provider': authUser.provider,
        'role': role,
        'accountType': _normalizeAccountType(existingData['accountType']),
        'isActive': (existingData['isActive'] ?? true) == true,
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!snapshot.exists) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }

      await docRef.set(payload, SetOptions(merge: true));
      final refreshed = await docRef.get();
      final data = refreshed.data() ?? payload;

      _currentUser = AppUser(
        id: authUser.id,
        email: (data['email'] as String?)?.trim().isNotEmpty == true
            ? (data['email'] as String).trim()
            : authUser.email,
        displayName: (data['name'] as String?)?.trim().isNotEmpty == true
            ? (data['name'] as String).trim()
            : authUser.displayName,
        photoUrl: (data['photoUrl'] as String?)?.trim().isEmpty ?? true
            ? authUser.photoUrl
            : data['photoUrl'] as String?,
        provider: (data['provider'] as String?)?.trim().isNotEmpty == true
            ? (data['provider'] as String).trim()
            : authUser.provider,
        createdAt: _toDateTime(data['createdAt']) ?? authUser.createdAt,
        role: _normalizeRole(data['role']),
        accountType: _normalizeAccountType(data['accountType']),
        isActive: (data['isActive'] ?? true) == true,
        hasCompletedOnboarding:
            (data['hasCompletedOnboarding'] ?? false) == true,
      );
      _error = null;
    } catch (error, stackTrace) {
      debugPrint('UserProvider.loadCurrentUser error: $error');
      debugPrint('$stackTrace');
      _error =
          'No fue posible cargar o sincronizar tu perfil en Firestore.';
      _currentUser = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _currentUser = null;
    _pendingInvitations = const [];
    _loading = false;
    _error = null;
    notifyListeners();
  }

  void _handleAuthChanged() {
    if (!_authProvider.isAuthenticated) {
      _pendingInvitesSubscription?.cancel();
      clear();
      return;
    }
    _watchPendingInvitations();
    unawaited(loadCurrentUser());
  }

  Future<String> _resolveUserRole({
    required String uid,
    required bool exists,
    required dynamic rawRole,
  }) async {
    if (rawRole is String) {
      final normalized = _normalizeRole(rawRole);
      if (normalized != 'viewer') return normalized;
    }
    final usersSnapshot = await _firestore.collection('users').limit(2).get();
    if (usersSnapshot.docs.isEmpty) return 'admin';
    if (exists &&
        usersSnapshot.docs.length == 1 &&
        usersSnapshot.docs.first.id == uid) {
      return 'admin';
    }
    return 'operator';
  }

  Future<void> setOnboardingCompleted(bool value) async {
    final userId = _authProvider.user?.id;
    if (userId == null) return;
    await _firestore.collection('users').doc(userId).set({
      'hasCompletedOnboarding': value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(hasCompletedOnboarding: value);
      notifyListeners();
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUsers() {
    final companyId = _currentCompanyProvider.companyId;
    if (!isAdmin || companyId == null) {
      return Stream<QuerySnapshot<Map<String, dynamic>>>.error(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Solo un administrador puede cargar miembros.',
        ),
      );
    }
    return FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('users')
        .orderBy('joinedAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchInvitations() {
    final companyId = _currentCompanyProvider.companyId;
    if (!isAdmin || companyId == null) {
      return Stream<QuerySnapshot<Map<String, dynamic>>>.error(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Solo un administrador puede cargar invitaciones.',
        ),
      );
    }
    return FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('invitations')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> updateUserRole({
    required String userId,
    required String role,
  }) async {
    final companyId = _currentCompanyProvider.companyId;
    if (!isAdmin || companyId == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Solo un administrador puede cambiar roles.',
      );
    }
    await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('users')
        .doc(userId)
        .set({
      'role': _normalizeRole(role),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setUserActive({
    required String userId,
    required bool isActive,
  }) async {
    final companyId = _currentCompanyProvider.companyId;
    if (!isAdmin || companyId == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Solo un administrador puede activar o desactivar usuarios.',
      );
    }
    await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('users')
        .doc(userId)
        .set({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<CompanyInvitation> inviteUser({
    String? email,
    required String role,
  }) async {
    final companyId = _currentCompanyProvider.companyId;
    final company = _currentCompanyProvider.company;
    final inviterId = _authProvider.user?.id;
    if (!isAdmin || companyId == null || company == null || inviterId == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Solo un administrador puede invitar miembros.',
      );
    }
    final normalizedEmail = (email ?? '').trim().toLowerCase();
    final usersSnapshot = normalizedEmail.isEmpty
        ? null
        : await _firestore
            .collection('users')
            .where('email', isEqualTo: normalizedEmail)
            .limit(1)
            .get();
    final existingInvite = normalizedEmail.isEmpty
        ? null
        : await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('invitations')
            .where('emailLower', isEqualTo: normalizedEmail)
            .where('status', isEqualTo: 'pending')
            .limit(1)
            .get();
    if (existingInvite != null && existingInvite.docs.isNotEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'already-exists',
        message: 'Ya existe una invitación pendiente para ese correo.',
      );
    }

    final membershipExists = usersSnapshot != null &&
        usersSnapshot.docs.isNotEmpty &&
        (await _firestore
                .collection('companies')
                .doc(companyId)
                .collection('users')
                .doc(usersSnapshot.docs.first.id)
                .get())
            .exists;
    if (membershipExists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'already-exists',
        message: 'Ese usuario ya pertenece a esta empresa.',
      );
    }

    final invitationRef = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('invitations')
        .doc();
    final inviteToken = '$companyId.${invitationRef.id}.${_generateTokenSuffix()}';
    final expiresAt = DateTime.now().add(const Duration(days: 7));
    await invitationRef.set({
      'id': invitationRef.id,
      'companyId': companyId,
      'companyName': company.companyName,
      'email': normalizedEmail,
      'emailLower': normalizedEmail,
      'role': _normalizeRole(role),
      'status': 'pending',
      'invitedBy': inviterId,
      'inviteeUid': usersSnapshot != null && usersSnapshot.docs.isNotEmpty
          ? usersSnapshot.docs.first.id
          : null,
      'inviteToken': inviteToken,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final invitationSnapshot = await invitationRef.get();
    return CompanyInvitation.fromFirestore(invitationSnapshot);
  }

  Future<void> revokeInvitation(String invitationId) async {
    final companyId = _currentCompanyProvider.companyId;
    if (!isAdmin || companyId == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Solo un administrador puede revocar invitaciones.',
      );
    }
    await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('invitations')
        .doc(invitationId)
        .set({
      'status': 'revoked',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> acceptInvitation(String invitationId) async {
    final inviteSnapshot = await _findInvitationById(invitationId);
    if (!inviteSnapshot.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'not-found',
        message: 'No encontramos la invitación.',
      );
    }
    await _acceptInvitationSnapshot(inviteSnapshot);
  }

  Future<void> rejectInvitation(String invitationId) async {
    final inviteSnapshot = await _findInvitationById(invitationId);
    if (!inviteSnapshot.exists) return;
    await inviteSnapshot.reference.set({
      'status': 'revoked',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    _watchPendingInvitations();
  }

  Future<CompanyInvitation?> getInvitationByToken(String inviteToken) async {
    final invitationRef = _invitationReferenceFromToken(inviteToken);
    if (invitationRef == null) return null;
    final snapshot = await invitationRef.get();
    if (!snapshot.exists) return null;
    final invitation = CompanyInvitation.fromFirestore(snapshot);
    return invitation.inviteToken == inviteToken ? invitation : null;
  }

  Future<void> acceptInvitationByToken(String inviteToken) async {
    final invitationRef = _invitationReferenceFromToken(inviteToken);
    if (invitationRef == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-argument',
        message: 'El link de invitación no es válido.',
      );
    }
    final snapshot = await invitationRef.get();
    if (!snapshot.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'not-found',
        message: 'La invitación ya no está disponible.',
      );
    }
    await _acceptInvitationSnapshot(snapshot, expectedToken: inviteToken);
  }

  Future<void> rejectInvitationByToken(String inviteToken) async {
    final authUser = _authProvider.user;
    if (authUser == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Debes iniciar sesión para rechazar una invitación.',
      );
    }
    final invitationRef = _invitationReferenceFromToken(inviteToken);
    if (invitationRef == null) return;
    final snapshot = await invitationRef.get();
    if (!snapshot.exists) return;
    final invitation = CompanyInvitation.fromFirestore(snapshot);
    _validateInvitationAccess(
      invitation: invitation,
      authEmail: authUser.email,
      expectedToken: inviteToken,
      allowExpired: true,
    );
    await invitationRef.set({
      'status': 'revoked',
      'inviteeUid': authUser.id,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    _watchPendingInvitations();
  }

  String buildInvitationLink(CompanyInvitation invitation) {
    return Uri.base.resolve('invite/${invitation.inviteToken}').toString();
  }

  Future<void> removeMember(String userId) async {
    final companyId = _currentCompanyProvider.companyId;
    if (!isAdmin || companyId == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Solo un administrador puede remover miembros.',
      );
    }
    if (userId == _authProvider.user?.id) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'failed-precondition',
        message: 'No puedes removerte a ti mismo de la empresa activa.',
      );
    }
    await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('users')
        .doc(userId)
        .delete();
    await _firestore.collection('users').doc(userId).set({
      'companyIds': FieldValue.arrayRemove([companyId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  String _normalizeRole(dynamic value) {
    final normalized = (value is String ? value : '').trim().toLowerCase();
    switch (normalized) {
      case 'admin':
      case 'editor':
      case 'operator':
      case 'viewer':
        return normalized;
      default:
        return 'viewer';
    }
  }

  Future<void> updateCurrentUserAccountType(String accountType) async {
    final userId = _authProvider.user?.id;
    if (userId == null) return;
    final normalized = _normalizeAccountType(accountType);
    await _firestore.collection('users').doc(userId).set({
      'accountType': normalized,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(accountType: normalized);
      notifyListeners();
    }
  }

  String _normalizeAccountType(dynamic value) {
    final normalized = (value is String ? value : '').trim().toLowerCase();
    return normalized == 'business' ? 'business' : 'person';
  }

  void _watchPendingInvitations() {
    _pendingInvitesSubscription?.cancel();
    final email = _authProvider.user?.email.trim().toLowerCase();
    if (email == null || email.isEmpty) {
      _pendingInvitations = const [];
      notifyListeners();
      return;
    }
    _pendingInvitesSubscription = _firestore
        .collectionGroup('invitations')
        .where('emailLower', isEqualTo: email)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      _pendingInvitations = snapshot.docs
          .map(CompanyInvitation.fromFirestore)
          .toList()
        ..sort((a, b) {
          final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return right.compareTo(left);
        });
      notifyListeners();
    });
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _findInvitationById(
    String invitationId,
  ) async {
    final email = _authProvider.user?.email.trim().toLowerCase();
    final snapshot = await _firestore
        .collectionGroup('invitations')
        .where('emailLower', isEqualTo: email)
        .where(FieldPath.documentId, isEqualTo: invitationId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return _firestore.collection('companies').doc('_missing').get();
    }
    return snapshot.docs.first;
  }

  Future<void> _acceptInvitationSnapshot(
    DocumentSnapshot<Map<String, dynamic>> inviteSnapshot, {
    String? expectedToken,
  }) async {
    final authUser = _authProvider.user;
    if (authUser == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Debes iniciar sesión para aceptar invitaciones.',
      );
    }
    final invitation = CompanyInvitation.fromFirestore(inviteSnapshot);
    _validateInvitationAccess(
      invitation: invitation,
      authEmail: authUser.email,
      expectedToken: expectedToken,
    );

    final batch = _firestore.batch();
    final membershipRef = _firestore
        .collection('companies')
        .doc(invitation.companyId)
        .collection('users')
        .doc(authUser.id);
    batch.set(membershipRef, {
      'uid': authUser.id,
      'displayName': authUser.displayName,
      'email': authUser.email,
      'role': _normalizeRole(invitation.role),
      'joinedAt': FieldValue.serverTimestamp(),
      'invitedBy': invitation.invitedBy,
      'status': 'accepted',
      'accountType': authUser.accountType,
      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(inviteSnapshot.reference, {
      'status': 'accepted',
      'inviteeUid': authUser.id,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(_firestore.collection('users').doc(authUser.id), {
      'companyIds': FieldValue.arrayUnion([invitation.companyId]),
      'currentCompanyId': invitation.companyId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
    await _currentCompanyProvider.refresh();
    _watchPendingInvitations();
  }

  void _validateInvitationAccess({
    required CompanyInvitation invitation,
    required String authEmail,
    String? expectedToken,
    bool allowExpired = false,
  }) {
    if (invitation.companyId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'failed-precondition',
        message: 'La invitación no tiene una empresa válida.',
      );
    }
    if (expectedToken != null && invitation.inviteToken != expectedToken) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'El token de invitación no coincide.',
      );
    }
    if (invitation.isAccepted) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'already-exists',
        message: 'Esta invitación ya fue aceptada.',
      );
    }
    if (invitation.isRevoked) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Esta invitación ya no está disponible.',
      );
    }
    if (!allowExpired && invitation.isExpired) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'deadline-exceeded',
        message: 'La invitación expiró.',
      );
    }
    final normalizedEmail = authEmail.trim().toLowerCase();
    if (invitation.hasEmailRestriction &&
        normalizedEmail != invitation.email.trim().toLowerCase()) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Esta invitación está asociada a otro correo.',
      );
    }
  }

  DocumentReference<Map<String, dynamic>>? _invitationReferenceFromToken(
    String inviteToken,
  ) {
    final parts = inviteToken.trim().split('.');
    if (parts.length < 3) return null;
    final companyId = parts[0].trim();
    final invitationId = parts[1].trim();
    if (companyId.isEmpty || invitationId.isEmpty) return null;
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('invitations')
        .doc(invitationId);
  }

  String _generateTokenSuffix() {
    final random = Random.secure();
    final bytes = List<int>.generate(12, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthChanged);
    _currentCompanyProvider.removeListener(_handleAuthChanged);
    _pendingInvitesSubscription?.cancel();
    super.dispose();
  }
}
