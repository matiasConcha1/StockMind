class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.provider,
    required this.createdAt,
    required this.role,
    this.isActive = true,
    this.hasCompletedOnboarding = false,
  });

  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String provider;
  final DateTime? createdAt;
  final String role;
  final bool isActive;
  final bool hasCompletedOnboarding;

  bool get isGoogleProvider => provider.toLowerCase() == 'google';
  bool get isEmailProvider => provider.toLowerCase() == 'email';
  String get providerLabel => isGoogleProvider ? 'Google' : 'Email';
  String get roleLabel => isAdmin ? 'Administrador' : 'Trabajador';

  String get normalizedRole {
    final value = role.trim().toLowerCase();
    if (value == 'admin') return 'admin';
    if (value == 'operator' || value == 'editor') return 'operator';
    return 'operator';
  }

  bool get isAdmin => normalizedRole == 'admin';
  bool get isOperator => normalizedRole == 'operator';
  bool get isEditor => isOperator;
  bool get canEdit => isActive && (isAdmin || isOperator);
  bool get canDelete => isAdmin;
  bool get canExport => isAdmin;
  bool get canManageUsers => isAdmin;
  bool get canManageSettings => isAdmin;
  bool get canApproveRequests => isAdmin;

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? provider,
    DateTime? createdAt,
    String? role,
    bool? isActive,
    bool? hasCompletedOnboarding,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      provider: provider ?? this.provider,
      createdAt: createdAt ?? this.createdAt,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }
}
