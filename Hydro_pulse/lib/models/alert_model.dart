import 'package:flutter/material.dart';

enum AlertSeverity { info, warning, critical }

class AlertModel {
  final int? id;
  final String title;
  final String message;
  final String sensorId;
  final double sensorValue;
  final String unit;
  final AlertSeverity severity;
  final DateTime timestamp;
  final bool isAcknowledged;

  AlertModel({
    this.id,
    required this.title,
    required this.message,
    required this.sensorId,
    required this.sensorValue,
    required this.unit,
    required this.severity,
    required this.timestamp,
    this.isAcknowledged = false,
  });

  // Create from SQLite map
  factory AlertModel.fromMap(Map<String, dynamic> map) {
    return AlertModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      message: map['message'] as String,
      sensorId: map['sensor_id'] as String,
      sensorValue: map['sensor_value'] as double,
      unit: map['unit'] as String,
      severity: AlertSeverity.values[map['severity'] as int],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      isAcknowledged: (map['is_acknowledged'] as int) == 1,
    );
  }

  // Convert to SQLite map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'message': message,
      'sensor_id': sensorId,
      'sensor_value': sensorValue,
      'unit': unit,
      'severity': severity.index,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'is_acknowledged': isAcknowledged ? 1 : 0,
    };
  }

  // Copy with
  AlertModel copyWith({
    int? id,
    String? title,
    String? message,
    String? sensorId,
    double? sensorValue,
    String? unit,
    AlertSeverity? severity,
    DateTime? timestamp,
    bool? isAcknowledged,
  }) {
    return AlertModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      sensorId: sensorId ?? this.sensorId,
      sensorValue: sensorValue ?? this.sensorValue,
      unit: unit ?? this.unit,
      severity: severity ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
    );
  }

  // Get icon based on severity
  IconData get icon {
    switch (severity) {
      case AlertSeverity.critical:
        return Icons.error;
      case AlertSeverity.warning:
        return Icons.warning_amber_rounded;
      case AlertSeverity.info:
        return Icons.info_outline;
    }
  }

  // Get color based on severity
  Color get color {
    switch (severity) {
      case AlertSeverity.critical:
        return const Color(0xFFFF5252);
      case AlertSeverity.warning:
        return const Color(0xFFFFA726);
      case AlertSeverity.info:
        return const Color(0xFF00BCD4);
    }
  }

  // Get severity label
  String get severityLabel {
    switch (severity) {
      case AlertSeverity.critical:
        return 'Critical';
      case AlertSeverity.warning:
        return 'Warning';
      case AlertSeverity.info:
        return 'Info';
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
