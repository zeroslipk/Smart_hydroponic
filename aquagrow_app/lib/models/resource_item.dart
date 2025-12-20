class ResourceItem {
  final int? id;
  final String providerId;
  final String providerName;
  final ResourceType type;
  final String description;
  final int quantity;
  final String? location;
  final DateTime timestamp;
  final bool isAvailable;
  final String? contactInfo;

  ResourceItem({
    this.id,
    required this.providerId,
    required this.providerName,
    required this.type,
    required this.description,
    required this.quantity,
    this.location,
    required this.timestamp,
    this.isAvailable = true,
    this.contactInfo,
  });

  factory ResourceItem.fromMap(Map<String, dynamic> map) {
    return ResourceItem(
      id: map['id'] as int?,
      providerId: map['provider_id'] as String,
      providerName: map['provider_name'] as String,
      type: ResourceType.values.firstWhere(
        (e) => e.toString() == 'ResourceType.${map['type']}',
        orElse: () => ResourceType.other,
      ),
      description: map['description'] as String,
      quantity: map['quantity'] as int,
      location: map['location'] as String?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      isAvailable: (map['is_available'] as int) == 1,
      contactInfo: map['contact_info'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'provider_id': providerId,
      'provider_name': providerName,
      'type': type.toString().split('.').last,
      'description': description,
      'quantity': quantity,
      'location': location,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'is_available': isAvailable ? 1 : 0,
      'contact_info': contactInfo,
    };
  }

  ResourceItem copyWith({
    int? id,
    String? providerId,
    String? providerName,
    ResourceType? type,
    String? description,
    int? quantity,
    String? location,
    DateTime? timestamp,
    bool? isAvailable,
    String? contactInfo,
  }) {
    return ResourceItem(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      type: type ?? this.type,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      location: location ?? this.location,
      timestamp: timestamp ?? this.timestamp,
      isAvailable: isAvailable ?? this.isAvailable,
      contactInfo: contactInfo ?? this.contactInfo,
    );
  }
}

enum ResourceType {
  medical,
  food,
  water,
  shelter,
  clothing,
  tools,
  communication,
  transportation,
  other,
}

extension ResourceTypeExtension on ResourceType {
  String get displayName {
    switch (this) {
      case ResourceType.medical:
        return 'Medical Supplies';
      case ResourceType.food:
        return 'Food';
      case ResourceType.water:
        return 'Water';
      case ResourceType.shelter:
        return 'Shelter';
      case ResourceType.clothing:
        return 'Clothing';
      case ResourceType.tools:
        return 'Tools';
      case ResourceType.communication:
        return 'Communication Equipment';
      case ResourceType.transportation:
        return 'Transportation';
      case ResourceType.other:
        return 'Other';
    }
  }
}

