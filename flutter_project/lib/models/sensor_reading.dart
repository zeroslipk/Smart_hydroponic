import 'package:flutter/material.dart';

class SensorReading {
  final String id;
  final double value;
  final String unit;
  final DateTime timestamp;
  final String status;
  final double min;
  final double max;

  SensorReading({
    required this.id,
    required this.value,
    required this.unit,
    required this.timestamp,
    required this.status,
    required this.min,
    required this.max,
  });

  // Create from Firebase JSON
  factory SensorReading.fromJson(String id, Map<dynamic, dynamic> json) {
    return SensorReading(
      id: id,
      value: (json['value'] ?? 0).toDouble(),
      unit: json['unit']?.toString() ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      status: json['status']?.toString() ?? 'unknown',
      min: (json['min'] ?? 0).toDouble(),
      max: (json['max'] ?? 100).toDouble(),
    );
  }

  // Convert to Firebase JSON
  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'unit': unit,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status,
      'min': min,
      'max': max,
    };
  }

  // Calculate progress (0.0 to 1.0) for liquid animation
  double get progress {
    if (max == min) return 0.0;
    return ((value - min) / (max - min)).clamp(0.0, 1.0);
  }

  // Get display value with proper decimal places
  String get displayValue {
    if (id == 'pH' || id == 'temperature') {
      return value.toStringAsFixed(1);
    }
    return value.toStringAsFixed(0);
  }

  // Get friendly display name
  String get displayName {
    switch (id) {
      case 'temperature':
        return 'Temperature';
      case 'waterLevel':
        return 'Water Level';
      case 'pH':
        return 'pH Level';
      case 'tds':
        return 'TDS/EC';
      case 'light':
        return 'Light';
      default:
        return id;
    }
  }

  // Get color based on sensor type
  Color get sensorColor {
    switch (id) {
      case 'temperature':
        return const Color(0xFFFF7043);
      case 'waterLevel':
        return const Color(0xFF00BCD4);
      case 'pH':
        return const Color(0xFF9C27B0);
      case 'tds':
        return const Color(0xFFFF9800);
      case 'light':
        return const Color(0xFFFFA726);
      default:
        return Colors.grey;
    }
  }

  // Get icon based on sensor type
  IconData get icon {
    switch (id) {
      case 'temperature':
        return Icons.thermostat_outlined;
      case 'waterLevel':
        return Icons.water_drop_outlined;
      case 'pH':
        return Icons.science_outlined;
      case 'tds':
        return Icons.electric_bolt_outlined;
      case 'light':
        return Icons.light_mode_outlined;
      default:
        return Icons.sensors;
    }
  }

  // Get status color
  Color get statusColor {
    switch (status) {
      case 'optimal':
        return const Color(0xFF7CB342);
      case 'good':
        return const Color(0xFF00BCD4);
      case 'warning':
        return const Color(0xFFFFA726);
      case 'critical':
        return const Color(0xFFFF5252);
      default:
        return Colors.grey;
    }
  }
}
