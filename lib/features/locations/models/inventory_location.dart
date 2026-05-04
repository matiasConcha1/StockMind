import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryLocation {
  const InventoryLocation({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final String type;
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryLocation copyWith({
    String? id,
    String? name,
    String? description,
    String? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory InventoryLocation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return InventoryLocation(
      id: (data['id'] ?? doc.id) as String,
      name: (data['name'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      type: (data['type'] ?? 'otro') as String,
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDate(data['updatedAt']),
    );
  }

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
