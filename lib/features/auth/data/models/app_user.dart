class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.provider,
    required this.createdAt,
    required this.role,
    this.accountType = 'person',
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
  final String accountType;
  final bool isActive;
  final bool hasCompletedOnboarding;

  bool get isGoogleProvider => provider.toLowerCase() == 'google';
  bool get isEmailProvider => provider.toLowerCase() == 'email';
  String get providerLabel => isGoogleProvider ? 'Google' : 'Email';
  String get roleLabel {
    switch (normalizedRole) {
      case 'admin':
        return 'Administrador';
      case 'editor':
        return 'Editor';
      case 'operator':
        return 'Operador';
      case 'viewer':
        return 'Visualizador';
      default:
        return 'Usuario';
    }
  }

  String get normalizedRole {
    final value = role.trim().toLowerCase();
    if (value == 'admin') return 'admin';
    if (value == 'editor') return 'editor';
    if (value == 'operator') return 'operator';
    if (value == 'viewer') return 'viewer';
    return 'viewer';
  }

  String get normalizedAccountType {
    final value = accountType.trim().toLowerCase();
    return value == 'business' ? 'business' : 'person';
  }

  bool get isAdmin => normalizedRole == 'admin';
  bool get isViewer => normalizedRole == 'viewer';
  bool get isOperator => normalizedRole == 'operator';
  bool get isEditor => normalizedRole == 'editor';
  bool get isBusinessAccount => normalizedAccountType == 'business';
  bool get requiresCompanyProfile => isBusinessAccount;
  bool get canViewInventory => isActive;
  bool get canManageCatalog => isActive && (isAdmin || isEditor);
  bool get canManageInventory =>
      isActive && (isAdmin || isEditor || isOperator);
  bool get canManageLocations => canManageCatalog;
  bool get canResolveAlerts => canManageInventory;
  bool get canCreateRequests => canManageInventory;
  bool get canEdit => canManageCatalog;
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
    String? accountType,
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
      accountType: accountType ?? this.accountType,
      isActive: isActive ?? this.isActive,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }
}
