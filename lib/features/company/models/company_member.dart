import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyMember {
  const CompanyMember({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.role,
    required this.status,
    required this.accountType,
    required this.joinedAt,
    required this.invitedBy,
    required this.isActive,
  });

  final String uid;
  final String displayName;
  final String email;
  final String role;
  final String status;
  final String accountType;
  final DateTime? joinedAt;
  final String? invitedBy;
  final bool isActive;

  factory CompanyMember.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return CompanyMember(
      uid: (data['uid'] ?? doc.id) as String,
      displayName: (data['displayName'] ?? data['name'] ?? 'Usuario') as String,
      email: (data['email'] ?? '') as String,
      role: (data['role'] ?? 'viewer') as String,
      status: (data['status'] ?? 'accepted') as String,
      accountType: (data['accountType'] ?? 'person') as String,
      joinedAt: _toDate(data['joinedAt']),
      invitedBy: (data['invitedBy'] as String?)?.trim().isEmpty ?? true
          ? null
          : data['invitedBy'] as String,
      isActive: (data['isActive'] ?? true) == true,
    );
  }

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
