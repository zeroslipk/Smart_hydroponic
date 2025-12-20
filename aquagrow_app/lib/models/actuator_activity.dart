import 'package:flutter/material.dart';

enum ActuatorActionType { manual, scheduled, auto }

class ActuatorActivity {
  final int? id;
  final String actuatorId;
  final String actuatorName;
  final bool isOn;
  final ActuatorActionType actionType;
  final DateTime timestamp;
  final int? durationSeconds;

  ActuatorActivity({
    this.id,
    required this.actuatorId,
    required this.actuatorName,
    required this.isOn,
    required this.actionType,
    required this.timestamp,
    this.durationSeconds,
  });

  // Create from SQLite map
  factory ActuatorActivity.fromMap(Map<String, dynamic> map) {
    return ActuatorActivity(
      id: map['id'] as int?,
      actuatorId: map['actuator_id'] as String,
      actuatorName: map['actuator_name'] as String,
      isOn: (map['is_on'] as int) == 1,
      actionType: ActuatorActionType.values[map['action_type'] as int],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      durationSeconds: map['duration_seconds'] as int?,
    );
  }

  // Convert to SQLite map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'actuator_id': actuatorId,
      'actuator_name': actuatorName,
      'is_on': isOn ? 1 : 0,
      'action_type': actionType.index,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'duration_seconds': durationSeconds,
    };
  }

  // Get action type label
  String get actionTypeLabel {
    switch (actionType) {
      case ActuatorActionType.manual:
        return 'Manual';
      case ActuatorActionType.scheduled:
        return 'Scheduled';
      case ActuatorActionType.auto:
        return 'Auto';
    }
  }

  // Get action description
  String get actionDescription {
    return '$actuatorName turned ${isOn ? 'ON' : 'OFF'}';
  }

  // Get icon
  IconData get icon {
    switch (actuatorId) {
      case 'pump':
        return Icons.water_drop;
      case 'lights':
        return Icons.lightbulb;
      case 'fan':
        return Icons.air;
      default:
        return Icons.settings_remote;
    }
  }

  // Get color
  Color get color {
    switch (actuatorId) {
      case 'pump':
        return const Color(0xFF00BCD4);
      case 'lights':
        return const Color(0xFFFFA726);
      case 'fan':
        return const Color(0xFF66BB6A);
      default:
        return Colors.grey;
    }
  }

  // Get time ago string
  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}
