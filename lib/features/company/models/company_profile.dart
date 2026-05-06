import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyProfile {
  const CompanyProfile({
    required this.id,
    required this.name,
    required this.industry,
    required this.phone,
    required this.email,
    required this.address,
    required this.website,
    required this.logoUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.isActive,
  });

  const CompanyProfile.empty()
      : id = 'company_profile',
        name = '',
        industry = '',
        phone = '',
        email = '',
        address = '',
        website = '',
        logoUrl = null,
        createdAt = null,
        updatedAt = null,
        createdBy = '',
        isActive = true;

  final String id;
  final String name;
  final String industry;
  final String phone;
  final String email;
  final String address;
  final String website;
  final String? logoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String createdBy;
  final bool isActive;

  bool get hasLogo => (logoUrl?.trim().isNotEmpty ?? false);
  bool get isComplete =>
      name.trim().isNotEmpty &&
      industry.trim().isNotEmpty &&
      phone.trim().isNotEmpty &&
      email.trim().isNotEmpty;

  CompanyProfile copyWith({
    String? id,
    String? name,
    String? industry,
    String? phone,
    String? email,
    String? address,
    String? website,
    String? logoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    bool? isActive,
  }) {
    return CompanyProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      industry: industry ?? this.industry,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      website: website ?? this.website,
      logoUrl: logoUrl ?? this.logoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap({required bool isNew}) {
    return {
      'id': id,
      'name': name.trim(),
      'industry': industry.trim(),
      'phone': phone.trim(),
      'email': email.trim(),
      'address': address.trim(),
      'website': website.trim(),
      'logoUrl': logoUrl,
      'createdBy': createdBy,
      'isActive': isActive,
      if (isNew) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory CompanyProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return CompanyProfile(
      id: (data['id'] ?? doc.id).toString(),
      name: (data['name'] ?? '').toString(),
      industry: (data['industry'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      address: (data['address'] ?? '').toString(),
      website: (data['website'] ?? '').toString(),
      logoUrl: (data['logoUrl'] as String?)?.trim().isEmpty ?? true
          ? null
          : data['logoUrl'] as String,
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
      createdBy: (data['createdBy'] ?? '').toString(),
      isActive: (data['isActive'] ?? true) == true,
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
