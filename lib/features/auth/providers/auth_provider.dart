import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:stockmind/features/auth/data/models/app_user.dart';
import 'package:stockmind/features/auth/data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService);

  final AuthService _authService;

  StreamSubscription<AppUser?>? _subscription;
  AppUser? _user;
  bool _initialized = false;
  bool _loading = false;
  String? _error;

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get initialized => _initialized;
  bool get isLoading => _loading;
  String? get error => _error;

  void start() {
    _subscription ??= _authService.authStateChanges().listen((user) {
      _user = user;
      _initialized = true;
      notifyListeners();
    });
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _run(
      () => _authService.signInWithEmail(email: email, password: password),
    );
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return _run(
      () => _authService.registerWithEmail(
        name: name,
        email: email,
        password: password,
      ),
    );
  }

  Future<bool> signInWithGoogle() async {
    return _run(_authService.signInWithGoogle);
  }

  Future<bool> sendResetEmail(String email) async {
    return _run(() => _authService.sendPasswordResetEmail(email));
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<bool> _run(Future<void> Function() action) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await action();
      return true;
    } on FirebaseAuthException catch (error) {
      _error = _mapFirebaseError(error);
      return false;
    } catch (_) {
      _error = 'No fue posible completar la operación.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  String _mapFirebaseError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'El correo no tiene un formato válido.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Credenciales incorrectas.';
      case 'email-already-in-use':
        return 'Ese correo ya está registrado.';
      case 'weak-password':
        return 'La contraseña es demasiado débil.';
      case 'network-request-failed':
        return 'No hay conexión disponible.';
      default:
        return 'No fue posible completar la operación.';
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
