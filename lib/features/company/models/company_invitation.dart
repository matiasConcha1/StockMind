import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyInvitation {
  const CompanyInvitation({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.email,
    required this.role,
    required this.status,
    required this.invitedBy,
    required this.inviteToken,
    required this.createdAt,
    required this.updatedAt,
    this.expiresAt,
    this.inviteeUid,
  });

  final String id;
  final String companyId;
  final String companyName;
  final String email;
  final String role;
  final String status;
  final String invitedBy;
  final String inviteToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;
  final String? inviteeUid;

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRevoked => status == 'revoked';
  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get hasEmailRestriction => email.trim().isNotEmpty;
  bool get canBeAccepted => isPending && !isExpired;

  factory CompanyInvitation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return CompanyInvitation(
      id: doc.id,
      companyId: (data['companyId'] ?? '') as String,
      companyName: (data['companyName'] ?? 'Empresa') as String,
      email: (data['email'] ?? '') as String,
      role: (data['role'] ?? 'viewer') as String,
      status: (data['status'] ?? 'pending') as String,
      invitedBy: (data['invitedBy'] ?? '') as String,
      inviteToken: (data['inviteToken'] ?? '') as String,
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDate(data['updatedAt']),
      expiresAt: _toDate(data['expiresAt']),
      inviteeUid: (data['inviteeUid'] as String?)?.trim().isEmpty ?? true
          ? null
          : data['inviteeUid'] as String,
    );
  }

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
