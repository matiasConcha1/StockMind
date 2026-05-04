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

  AppUser? get currentUser => _mapUser(_auth.currentUser);

  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().map(_mapUser);
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

  AppUser? _mapUser(User? user) {
    if (user == null) return null;
    return AppUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? 'Administrador',
      photoUrl: user.photoURL,
    );
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

  Future<void> _upsertUserDocument({
    required User user,
    required String provider,
    String? fallbackName,
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
    final data = <String, dynamic>{
      'uid': user.uid,
      'name': name,
      'email': user.email ?? '',
      'provider': provider,
      'photoUrl': user.photoURL,
    };

    if (!snapshot.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await docRef.set(data, SetOptions(merge: true));
  }
}
