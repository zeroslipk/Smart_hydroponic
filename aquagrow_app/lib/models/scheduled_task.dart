import 'package:flutter/material.dart';

class ScheduledTask {
  final int? id;
  final String actuatorId;
  final String actuatorName;
  final String scheduleType; // 'interval' or 'daily'
  final int? intervalMinutes; // For interval-based schedules
  final String? startTime; // For daily schedules (HH:mm)
  final String? endTime; // For daily schedules (HH:mm)
  final int durationMinutes;
  final bool isEnabled;
  final List<int> daysOfWeek; // 0 = Monday, 6 = Sunday
  final DateTime createdAt;

  ScheduledTask({
    this.id,
    required this.actuatorId,
    required this.actuatorName,
    required this.scheduleType,
    this.intervalMinutes,
    this.startTime,
    this.endTime,
    required this.durationMinutes,
    this.isEnabled = true,
    this.daysOfWeek = const [0, 1, 2, 3, 4, 5, 6],
    required this.createdAt,
  });

  // Create from SQLite map
  factory ScheduledTask.fromMap(Map<String, dynamic> map) {
    return ScheduledTask(
      id: map['id'] as int?,
      actuatorId: map['actuator_id'] as String,
      actuatorName: map['actuator_name'] as String,
      scheduleType: map['schedule_type'] as String,
      intervalMinutes: map['interval_minutes'] as int?,
      startTime: map['start_time'] as String?,
      endTime: map['end_time'] as String?,
      durationMinutes: map['duration_minutes'] as int,
      isEnabled: (map['is_enabled'] as int) == 1,
      daysOfWeek: (map['days_of_week'] as String)
          .split(',')
          .where((s) => s.isNotEmpty)
          .map((s) => int.parse(s))
          .toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  // Convert to SQLite map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'actuator_id': actuatorId,
      'actuator_name': actuatorName,
      'schedule_type': scheduleType,
      'interval_minutes': intervalMinutes,
      'start_time': startTime,
      'end_time': endTime,
      'duration_minutes': durationMinutes,
      'is_enabled': isEnabled ? 1 : 0,
      'days_of_week': daysOfWeek.join(','),
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  // Copy with
  ScheduledTask copyWith({
    int? id,
    String? actuatorId,
    String? actuatorName,
    String? scheduleType,
    int? intervalMinutes,
    String? startTime,
    String? endTime,
    int? durationMinutes,
    bool? isEnabled,
    List<int>? daysOfWeek,
    DateTime? createdAt,
  }) {
    return ScheduledTask(
      id: id ?? this.id,
      actuatorId: actuatorId ?? this.actuatorId,
      actuatorName: actuatorName ?? this.actuatorName,
      scheduleType: scheduleType ?? this.scheduleType,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isEnabled: isEnabled ?? this.isEnabled,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Get schedule description
  String get scheduleDescription {
    if (scheduleType == 'interval') {
      final hours = intervalMinutes! ~/ 60;
      final mins = intervalMinutes! % 60;
      String interval = '';
      if (hours > 0) interval += '${hours}h ';
      if (mins > 0) interval += '${mins}m';
      return 'Every $interval, ${durationMinutes}min duration';
    } else {
      return '$startTime - $endTime daily';
    }
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
        return Icons.schedule;
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
}
