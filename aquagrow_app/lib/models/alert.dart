import 'package:flutter/material.dart';

class Alert {
  final int? id;
  final String sensorId;
  final String message;
  final String severity; // 'info', 'warning', 'critical'
  final DateTime timestamp;
  final bool acknowledged;
  final DateTime? acknowledgedAt;

  Alert({
    this.id,
    required this.sensorId,
    required this.message,
    required this.severity,
    required this.timestamp,
    this.acknowledged = false,
    this.acknowledgedAt,
  });

  // Create from database map
  factory Alert.fromMap(Map<String, dynamic> map) {
    return Alert(
      id: map['id'] as int?,
      sensorId: map['sensor_id'] as String,
      message: map['message'] as String,
      severity: map['severity'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      acknowledged: (map['acknowledged'] as int) == 1,
      acknowledgedAt: map['acknowledged_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['acknowledged_at'] as int)
          : null,
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sensor_id': sensorId,
      'message': message,
      'severity': severity,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'acknowledged': acknowledged ? 1 : 0,
      'acknowledged_at': acknowledgedAt?.millisecondsSinceEpoch,
    };
  }

  // Get severity color
  Color get severityColor {
    switch (severity) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Get severity icon
  IconData get severityIcon {
    switch (severity) {
      case 'critical':
        return Icons.error;
      case 'warning':
        return Icons.warning;
      case 'info':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }
}






