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
        role: 'editor',
      );

  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      final role = await _fetchUserRole(user.uid);
      return _mapUser(user, role: role);
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

  AppUser? _mapUser(User? user, {required String role}) {
    if (user == null) return null;
    return AppUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: (user.displayName?.trim().isNotEmpty ?? false)
          ? user.displayName!.trim()
          : 'Administrador',
      photoUrl: user.photoURL,
      provider: _resolveProvider(user),
      createdAt: user.metadata.creationTime,
      role: role,
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

  Future<String> _fetchUserRole(String uid) async {
    try {
      final snapshot = await _firestore.collection('users').doc(uid).get();
      final value = snapshot.data()?['role'];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim().toLowerCase();
      }
    } catch (error, stackTrace) {
      debugPrint('AuthService._fetchUserRole error: $error');
      debugPrint('$stackTrace');
    }
    return 'editor';
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
    final existingRole = snapshot.data()?['role'];
    final role = existingRole is String && existingRole.trim().isNotEmpty
        ? existingRole.trim().toLowerCase()
        : 'editor';

    final data = <String, dynamic>{
      'uid': user.uid,
      'name': name,
      'email': user.email ?? '',
      'provider': provider,
      'role': role,
      'photoUrl': (overridePhotoUrl?.isNotEmpty ?? false)
          ? overridePhotoUrl
          : user.photoURL,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!snapshot.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await docRef.set(data, SetOptions(merge: true));
  }
}
