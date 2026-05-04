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
  bool _loading = true;
  String? _error;

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get initialized => _initialized;
  bool get isLoading => _loading;
  String? get error => _error;

  void start() {
    if (_subscription != null) return;

    debugPrint('AuthProvider.start: subscribing to authStateChanges');
    _loading = true;
    _error = null;
    notifyListeners();

    _subscription = _authService.authStateChanges().listen(
      (user) {
        debugPrint(
          'AuthProvider.authStateChanges: user=${user?.email ?? 'null'}',
        );
        _user = user;
        _initialized = true;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('AuthProvider.authStateChanges error: $error');
        debugPrint('$stackTrace');
        _user = null;
        _initialized = true;
        _loading = false;
        _error = 'No fue posible verificar la sesión.';
        notifyListeners();
      },
    );
  }

  void completeLoadingFallback() {
    debugPrint('AuthProvider.completeLoadingFallback: forcing unauthenticated state');
    _user = null;
    _initialized = true;
    _loading = false;
    notifyListeners();
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
    debugPrint('AuthProvider.signOut: starting');
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.signOut();
      debugPrint('AuthProvider.signOut: success');
    } catch (error, stackTrace) {
      debugPrint('AuthProvider.signOut error: $error');
      debugPrint('$stackTrace');
      _error = 'No fue posible cerrar la sesión.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> _run(Future<void> Function() action) async {
    _loading = true;
    _error = null;
    notifyListeners();
    debugPrint('AuthProvider._run: action started');

    try {
      await action();
      debugPrint('AuthProvider._run: action completed');
      return true;
    } on FirebaseAuthException catch (error) {
      debugPrint('AuthProvider._run FirebaseAuthException: ${error.code}');
      _error = _mapFirebaseError(error);
      return false;
    } catch (error, stackTrace) {
      debugPrint('AuthProvider._run error: $error');
      debugPrint('$stackTrace');
      _error = 'No fue posible completar la operación.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
      debugPrint('AuthProvider._run: loading finished');
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
