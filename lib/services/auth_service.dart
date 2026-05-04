import 'package:stockmind/models/app_user.dart';

class AuthService {
  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    _currentUser = AppUser(
      name: 'Usuario StockMind',
      email: email,
      userType: UserType.negocio,
    );
    return _currentUser!;
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required UserType userType,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    _currentUser = AppUser(name: name, email: email, userType: userType);
    return _currentUser!;
  }

  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _currentUser = null;
  }
}
