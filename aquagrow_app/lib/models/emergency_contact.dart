class EmergencyContact {
  final int? id;
  final String name;
  final String phoneNumber;
  final String? email;
  final String relationship; // family, friend, emergency_services, etc.
  final bool isPrimary;
  final DateTime createdAt;

  EmergencyContact({
    this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    required this.relationship,
    this.isPrimary = false,
    required this.createdAt,
  });

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      id: map['id'] as int?,
      name: map['name'] as String,
      phoneNumber: map['phone_number'] as String,
      email: map['email'] as String?,
      relationship: map['relationship'] as String,
      isPrimary: (map['is_primary'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'email': email,
      'relationship': relationship,
      'is_primary': isPrimary ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  EmergencyContact copyWith({
    int? id,
    String? name,
    String? phoneNumber,
    String? email,
    String? relationship,
    bool? isPrimary,
    DateTime? createdAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

