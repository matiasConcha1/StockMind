enum UserType { hogar, negocio }

class AppUser {
  const AppUser({
    required this.name,
    required this.email,
    required this.userType,
  });

  final String name;
  final String email;
  final UserType userType;

  String get userTypeLabel => userType == UserType.hogar ? 'Hogar' : 'Negocio';
}
