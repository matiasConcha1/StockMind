import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:stockmind/features/auth/data/models/app_user.dart';

class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AppUser? get currentUser => _mapUser(
        _auth.currentUser,
        role: 'operator',
        hasCompletedOnboarding: false,
      );

  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      final profile = await _fetchUserProfile(user.uid);
      return _mapUser(
        user,
        role: profile.role,
        isActive: profile.isActive,
        hasCompletedOnboarding: profile.hasCompletedOnboarding,
      );
    });
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
    required bool rememberSession,
  }) async {
    debugPrint('AuthService.signInWithEmail: signing in $email');
    await _configureSessionPersistence(rememberSession: rememberSession);
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      await _upsertUserDocument(
        user: user,
        provider: 'email',
        fallbackName: user.displayName,
      );
    }
  }

  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    debugPrint('AuthService.registerWithEmail: creating user $email');
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(name);
    await credential.user?.reload();
    final refreshedUser = _auth.currentUser;
    if (refreshedUser != null) {
      await _upsertUserDocument(
        user: refreshedUser,
        provider: 'email',
        fallbackName: name,
      );
    }
  }

  Future<void> updateProfile({
    required String displayName,
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No hay una sesión activa.',
      );
    }

    final normalizedPhotoUrl = photoUrl?.trim();
    await user.updateDisplayName(displayName.trim());
    await user.updatePhotoURL(
      normalizedPhotoUrl == null || normalizedPhotoUrl.isEmpty
          ? null
          : normalizedPhotoUrl,
    );
    await user.reload();

    final refreshedUser = _auth.currentUser;
    if (refreshedUser != null) {
      await _upsertUserDocument(
        user: refreshedUser,
        provider: _resolveProvider(refreshedUser),
        fallbackName: displayName.trim(),
        overridePhotoUrl: normalizedPhotoUrl,
      );
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signInWithGoogle({
    required bool rememberSession,
  }) async {
    debugPrint('AuthService.signInWithGoogle: starting');
    await _configureSessionPersistence(rememberSession: rememberSession);
    if (kIsWeb) {
      final credential = await _auth.signInWithPopup(GoogleAuthProvider());
      if (credential.user != null) {
        await _upsertUserDocument(
          user: credential.user!,
          provider: 'google',
          fallbackName: credential.user!.displayName,
        );
      }
      return;
    }

    await GoogleSignIn.instance.initialize();
    final googleUser = await GoogleSignIn.instance.authenticate();
    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);
    final userCredential = await _auth.signInWithCredential(credential);
    if (userCredential.user != null) {
      await _upsertUserDocument(
        user: userCredential.user!,
        provider: 'google',
        fallbackName: userCredential.user!.displayName,
      );
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      await GoogleSignIn.instance.signOut();
    }
  }

  AppUser? _mapUser(
    User? user, {
    required String role,
    bool isActive = true,
    bool hasCompletedOnboarding = false,
  }) {
    if (user == null) return null;
    return AppUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: (user.displayName?.trim().isNotEmpty ?? false)
          ? user.displayName!.trim()
          : 'Usuario StockMind',
      photoUrl: user.photoURL,
      provider: _resolveProvider(user),
      createdAt: user.metadata.creationTime,
      role: role,
      isActive: isActive,
      hasCompletedOnboarding: hasCompletedOnboarding,
    );
  }

  String _resolveProvider(User user) {
    final providerId = user.providerData
        .map((item) => item.providerId)
        .firstWhere(
          (value) => value == 'google.com' || value == 'password',
          orElse: () => '',
        );

    return switch (providerId) {
      'google.com' => 'google',
      'password' => 'email',
      _ => 'email',
    };
  }

  Future<void> _configureSessionPersistence({
    required bool rememberSession,
  }) async {
    if (!kIsWeb) return;
    try {
      await _auth.setPersistence(
        rememberSession ? Persistence.LOCAL : Persistence.SESSION,
      );
    } catch (error, stackTrace) {
      debugPrint('AuthService._configureSessionPersistence error: $error');
      debugPrint('$stackTrace');
      throw FirebaseAuthException(
        code: 'session-persistence-failed',
        message: 'No se pudo configurar la persistencia de sesión.',
      );
    }
  }

  Future<_UserProfileSnapshot> _fetchUserProfile(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    final data = snapshot.data() ?? const <String, dynamic>{};
    final role = await _resolveUserRole(
      uid: uid,
      exists: snapshot.exists,
      rawRole: data['role'],
    );
    return _UserProfileSnapshot(
      role: role,
      isActive: (data['isActive'] ?? true) == true,
      hasCompletedOnboarding: (data['hasCompletedOnboarding'] ?? false) == true,
    );
  }

  Future<void> _upsertUserDocument({
    required User user,
    required String provider,
    String? fallbackName,
    String? overridePhotoUrl,
  }) async {
    final name = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : (fallbackName?.trim().isNotEmpty ?? false)
            ? fallbackName!.trim()
        : 'Usuario StockMind';

    debugPrint(
      'AuthService._upsertUserDocument: uid=${user.uid} provider=$provider',
    );

    final docRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await docRef.get();
    final role = await _resolveUserRole(
      uid: user.uid,
      exists: snapshot.exists,
      rawRole: snapshot.data()?['role'],
    );
    final existingIsActive = snapshot.data()?['isActive'];

    final data = <String, dynamic>{
      'uid': user.uid,
      'name': name,
      'email': user.email ?? '',
      'provider': provider,
      'role': role,
      'isActive': existingIsActive is bool ? existingIsActive : true,
      'photoUrl': (overridePhotoUrl?.isNotEmpty ?? false)
          ? overridePhotoUrl
          : user.photoURL,
      'hasCompletedOnboarding': snapshot.exists
          ? (snapshot.data()?['hasCompletedOnboarding'] ?? false) == true
          : false,
      'lastLoginAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!snapshot.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await docRef.set(data, SetOptions(merge: true));
  }

  Future<String> _resolveUserRole({
    required String uid,
    required bool exists,
    required dynamic rawRole,
  }) async {
    if (rawRole is String && rawRole.trim().isNotEmpty) {
      return _normalizeRole(rawRole);
    }
    final isFirstUser = await _isFirstSystemUser(uid, exists: exists);
    return isFirstUser ? 'admin' : 'operator';
  }

  Future<bool> _isFirstSystemUser(String uid, {required bool exists}) async {
    final usersSnapshot = await _firestore.collection('users').limit(2).get();
    if (usersSnapshot.docs.isEmpty) return true;
    if (!exists) return false;
    if (usersSnapshot.docs.length == 1 && usersSnapshot.docs.first.id == uid) {
      return true;
    }
    return false;
  }

  String _normalizeRole(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'admin') return 'admin';
    if (normalized == 'operator' || normalized == 'editor') return 'operator';
    return 'operator';
  }
}

class _UserProfileSnapshot {
  const _UserProfileSnapshot({
    required this.role,
    required this.isActive,
    required this.hasCompletedOnboarding,
  });

  final String role;
  final bool isActive;
  final bool hasCompletedOnboarding;
}
