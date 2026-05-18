import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyWorkspace {
  const CompanyWorkspace({
    required this.id,
    required this.ownerId,
    required this.plan,
    required this.companyName,
    required this.logoUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.settings,
    required this.role,
    required this.accountType,
    required this.joinedAt,
    this.invitedBy,
    this.status = 'accepted',
  });

  final String id;
  final String ownerId;
  final String plan;
  final String companyName;
  final String? logoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> settings;
  final String role;
  final String accountType;
  final DateTime? joinedAt;
  final String? invitedBy;
  final String status;

  bool get isComplete => companyName.trim().isNotEmpty;
  bool get isDemoMode => settings['demoMode'] == true;
  bool get isSharedDemo => settings['sharedDemo'] == true;
  String get workspaceType {
    final raw =
        (settings['workspaceType'] ?? settings['accountType'] ?? accountType)
            .toString()
            .trim()
            .toLowerCase();
    switch (raw) {
      case 'personal':
      case 'person':
        return 'personal';
      case 'business':
      case 'negocio':
        return 'business';
      case 'company':
      case 'empresa':
        return 'company';
      default:
        return normalizedAccountType == 'person' ? 'personal' : 'business';
    }
  }
  String get normalizedAccountType {
    return accountType.trim().toLowerCase() == 'business'
        ? 'business'
        : 'person';
  }
  bool get isPersonalWorkspace => workspaceType == 'personal';
  String get workspaceBadgeLabel {
    switch (workspaceType) {
      case 'personal':
        return 'Personal';
      case 'company':
        return 'Empresa';
      default:
        return 'Negocio';
    }
  }

  CompanyWorkspace copyWith({
    String? id,
    String? ownerId,
    String? plan,
    String? companyName,
    String? logoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? settings,
    String? role,
    String? accountType,
    DateTime? joinedAt,
    String? invitedBy,
    String? status,
  }) {
    return CompanyWorkspace(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      plan: plan ?? this.plan,
      companyName: companyName ?? this.companyName,
      logoUrl: logoUrl ?? this.logoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      settings: settings ?? this.settings,
      role: role ?? this.role,
      accountType: accountType ?? this.accountType,
      joinedAt: joinedAt ?? this.joinedAt,
      invitedBy: invitedBy ?? this.invitedBy,
      status: status ?? this.status,
    );
  }

  factory CompanyWorkspace.fromSnapshots({
    required DocumentSnapshot<Map<String, dynamic>> companyDoc,
    required DocumentSnapshot<Map<String, dynamic>> membershipDoc,
  }) {
    final companyData = companyDoc.data() ?? const <String, dynamic>{};
    final membershipData = membershipDoc.data() ?? const <String, dynamic>{};
    return CompanyWorkspace(
      id: companyDoc.id,
      ownerId: (companyData['ownerId'] ?? '') as String,
      plan: (companyData['plan'] ?? 'trial') as String,
      companyName: (companyData['companyName'] ?? companyData['name'] ?? '')
          as String,
      logoUrl: (companyData['logoUrl'] as String?)?.trim().isEmpty ?? true
          ? null
          : companyData['logoUrl'] as String,
      createdAt: _toDate(companyData['createdAt']),
      updatedAt: _toDate(companyData['updatedAt']),
      settings:
          (companyData['settings'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
      role: (membershipData['role'] ?? 'viewer') as String,
      accountType: (membershipData['accountType'] ?? 'person') as String,
      joinedAt: _toDate(membershipData['joinedAt']),
      invitedBy: (membershipData['invitedBy'] as String?)?.trim().isEmpty ?? true
          ? null
          : membershipData['invitedBy'] as String,
      status: (membershipData['status'] ?? 'accepted') as String,
    );
  }

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
