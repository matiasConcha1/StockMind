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
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isOperator => _user?.isOperator ?? false;
  bool get isEditor => _user?.isEditor ?? false;
  bool get canEdit => _user?.canEdit ?? false;
  bool get canDelete => _user?.canDelete ?? false;
  bool get canExport => _user?.canExport ?? false;
  bool get canManageUsers => _user?.canManageUsers ?? false;
  bool get canManageSettings => _user?.canManageSettings ?? false;
  bool get canApproveRequests => _user?.canApproveRequests ?? false;

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
    debugPrint(
      'AuthProvider.completeLoadingFallback: forcing unauthenticated state',
    );
    _user = null;
    _initialized = true;
    _loading = false;
    notifyListeners();
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
    required bool rememberSession,
  }) async {
    debugPrint('AuthProvider.signInWithEmail: $email');
    return _run(
      () => _authService.signInWithEmail(
        email: email,
        password: password,
        rememberSession: rememberSession,
      ),
    );
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    debugPrint('AuthProvider.register: $email');
    return _run(
      () => _authService.registerWithEmail(
        name: name,
        email: email,
        password: password,
      ),
    );
  }

  Future<bool> signInWithGoogle({required bool rememberSession}) async {
    debugPrint('AuthProvider.signInWithGoogle: starting');
    return _run(
      () => _authService.signInWithGoogle(
        rememberSession: rememberSession,
      ),
    );
  }

  Future<bool> updateProfile({
    required String displayName,
    String? photoUrl,
  }) async {
    debugPrint('AuthProvider.updateProfile: ${_user?.email ?? 'unknown'}');
    return _run(
      () => _authService.updateProfile(
        displayName: displayName,
        photoUrl: photoUrl,
      ),
    );
  }

  Future<bool> sendResetEmail(String email) async {
    debugPrint('AuthProvider.sendResetEmail: $email');
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
      _user = _authService.currentUser;
      _initialized = true;
      debugPrint('AuthProvider._run: action completed');
      return true;
    } on FirebaseAuthException catch (error) {
      debugPrint('AuthProvider._run FirebaseAuthException: ${error.code}');
      _error = _mapFirebaseError(error);
      return false;
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('AuthProvider._run FirebaseException: ${error.code}');
      debugPrint('$stackTrace');
      _error = _mapFirestoreError(error);
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
      case 'user-not-found':
        return 'No existe una cuenta con este correo.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'invalid-email':
        return 'Correo inválido.';
      case 'email-already-in-use':
        return 'Este correo ya está registrado.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'popup-closed-by-user':
        return 'Inicio con Google cancelado.';
      case 'network-request-failed':
        return 'No hay conexión disponible.';
      case 'session-persistence-failed':
        return 'No se pudo configurar la persistencia de sesión.';
      case 'no-current-user':
        return 'No hay una sesión activa.';
      default:
        return 'No fue posible completar la operación.';
    }
  }

  String _mapFirestoreError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'No tienes permisos para completar el acceso. Revisa las reglas de Firestore.';
      case 'unavailable':
        return 'Firebase no está disponible en este momento. Intenta nuevamente.';
      default:
        return error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'No fue posible completar la operación.';
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
