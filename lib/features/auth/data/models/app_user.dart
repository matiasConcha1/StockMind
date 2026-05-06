class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.provider,
    required this.createdAt,
    required this.role,
  });

  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String provider;
  final DateTime? createdAt;
  final String role;

  bool get isGoogleProvider => provider.toLowerCase() == 'google';
  bool get isEmailProvider => provider.toLowerCase() == 'email';
  String get providerLabel => isGoogleProvider ? 'Google' : 'Email';

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isEditor => role.toLowerCase() == 'editor';
  bool get canEdit => isAdmin || isEditor;
  bool get canDelete => isAdmin;

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? provider,
    DateTime? createdAt,
    String? role,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      provider: provider ?? this.provider,
      createdAt: createdAt ?? this.createdAt,
      role: role ?? this.role,
    );
  }
}
