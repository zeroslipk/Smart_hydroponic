class SensorActivity {
  final int? id;
  final String sensorId;
  final String sensorName;
  final double value;
  final String unit;
  final String status;
  final DateTime timestamp;

  SensorActivity({
    this.id,
    required this.sensorId,
    required this.sensorName,
    required this.value,
    required this.unit,
    required this.status,
    required this.timestamp,
  });

  // Create from SQLite map
  factory SensorActivity.fromMap(Map<String, dynamic> map) {
    return SensorActivity(
      id: map['id'] as int?,
      sensorId: map['sensor_id'] as String,
      sensorName: map['sensor_name'] as String,
      value: map['value'] as double,
      unit: map['unit'] as String,
      status: map['status'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }

  // Convert to SQLite map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'sensor_id': sensorId,
      'sensor_name': sensorName,
      'value': value,
      'unit': unit,
      'status': status,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}
