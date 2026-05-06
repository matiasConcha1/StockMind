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
  bool get isEditor => _currentUser?.isEditor ?? false;
  bool get canEdit => _currentUser?.canEdit ?? false;
  bool get canDelete => _currentUser?.canDelete ?? false;

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
      final role = _resolveRole(existingData['role']);

      final payload = <String, dynamic>{
        'uid': authUser.id,
        'email': authUser.email,
        'name': authUser.displayName,
        'photoUrl': authUser.photoUrl,
        'provider': authUser.provider,
        'role': snapshot.exists ? role : 'editor',
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
        role: _resolveRole(data['role']),
      );
      _error = null;
    } catch (error, stackTrace) {
      debugPrint('UserProvider.loadCurrentUser error: $error');
      debugPrint('$stackTrace');
      _error = 'No fue posible cargar el usuario actual.';
      _currentUser = _authProvider.user?.copyWith(role: 'editor');
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

  String _resolveRole(dynamic value) {
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'admin' || normalized == 'editor') {
        return normalized;
      }
    }
    return 'editor';
  }

  DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthChanged);
    super.dispose();
  }
}
