import 'package:flutter/foundation.dart';
import 'package:stockmind/models/app_user.dart';
import 'package:stockmind/services/auth_service.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._authService);

  final AuthService _authService;

  AppUser? get currentUser => _authService.currentUser;
  bool get isAuthenticated => currentUser != null;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    return _runAction(() async {
      await _authService.login(email: email, password: password);
    });
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required UserType userType,
  }) async {
    return _runAction(() async {
      await _authService.register(
        name: name,
        email: email,
        password: password,
        userType: userType,
      );
    });
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _authService.logout();
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> _runAction(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } catch (_) {
      _errorMessage = 'No fue posible completar la operacion.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
