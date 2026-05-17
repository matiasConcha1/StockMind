import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:stockmind/features/auth/data/models/app_user.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';

class UserProvider extends ChangeNotifier {
  UserProvider({
    required AuthProvider authProvider,
    FirebaseFirestore? firestore,
  })  : _authProvider = authProvider,
        _firestore = firestore ?? FirebaseFirestore.instance {
    _authProvider.addListener(_handleAuthChanged);
    _handleAuthChanged();
  }

  final AuthProvider _authProvider;
  final FirebaseFirestore _firestore;

  AppUser? _currentUser;
  bool _loading = false;
  String? _error;
  Future<void>? _pendingLoad;

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
    _loading = false;
    _error = null;
    notifyListeners();
  }

  void _handleAuthChanged() {
    if (!_authProvider.isAuthenticated) {
      clear();
      return;
    }
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
    if (!isAdmin) {
      return Stream<QuerySnapshot<Map<String, dynamic>>>.error(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Solo un administrador puede cargar usuarios.',
        ),
      );
    }
    return FirebaseFirestore.instance
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> updateUserRole({
    required String userId,
    required String role,
  }) async {
    if (!isAdmin) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Solo un administrador puede cambiar roles.',
      );
    }
    await _firestore.collection('users').doc(userId).set({
      'role': _normalizeRole(role),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setUserActive({
    required String userId,
    required bool isActive,
  }) async {
    if (!isAdmin) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Solo un administrador puede activar o desactivar usuarios.',
      );
    }
    await _firestore.collection('users').doc(userId).set({
      'isActive': isActive,
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

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthChanged);
    super.dispose();
  }
}
