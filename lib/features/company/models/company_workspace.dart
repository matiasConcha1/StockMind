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

  bool get isComplete => companyName.trim().isNotEmpty;

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
    );
  }

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
