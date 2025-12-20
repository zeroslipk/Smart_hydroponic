class ActuatorActivity {
  final int? id;
  final String actuatorId;
  final String action; // 'on', 'off', 'set_level'
  final double? value;
  final String mode; // 'manual', 'automatic', 'scheduled'
  final DateTime timestamp;
  final String? userId;
  final String? notes;

  ActuatorActivity({
    this.id,
    required this.actuatorId,
    required this.action,
    this.value,
    required this.mode,
    required this.timestamp,
    this.userId,
    this.notes,
  });

  // Create from database map
  factory ActuatorActivity.fromMap(Map<String, dynamic> map) {
    return ActuatorActivity(
      id: map['id'] as int?,
      actuatorId: map['actuator_id'] as String,
      action: map['action'] as String,
      value: map['value'] != null ? (map['value'] as num).toDouble() : null,
      mode: map['mode'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      userId: map['user_id'] as String?,
      notes: map['notes'] as String?,
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'actuator_id': actuatorId,
      'action': action,
      'value': value,
      'mode': mode,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'user_id': userId,
      'notes': notes,
    };
  }

  // Get friendly display name
  String get displayName {
    switch (actuatorId) {
      case 'pump':
        return 'Water Pump';
      case 'led':
        return 'LED Lights';
      case 'fan':
        return 'Cooling Fan';
      case 'doser':
        return 'Nutrient Doser';
      default:
        return actuatorId;
    }
  }
}






