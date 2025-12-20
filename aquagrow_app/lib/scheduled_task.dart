class ScheduledTask {
  final int? id;
  final String taskName;
  final String actuatorId;
  final String action;
  final double? value;
  final String scheduleType; // 'daily', 'weekly', 'once'
  final String? scheduleTime; // HH:mm format
  final List<int>? weekDays; // 0-6 (Sunday-Saturday)
  final DateTime? scheduledDate; // For 'once' type
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastExecuted;

  ScheduledTask({
    this.id,
    required this.taskName,
    required this.actuatorId,
    required this.action,
    this.value,
    required this.scheduleType,
    this.scheduleTime,
    this.weekDays,
    this.scheduledDate,
    this.isActive = true,
    required this.createdAt,
    this.lastExecuted,
  });

  // Create from database map
  factory ScheduledTask.fromMap(Map<String, dynamic> map) {
    return ScheduledTask(
      id: map['id'] as int?,
      taskName: map['task_name'] as String,
      actuatorId: map['actuator_id'] as String,
      action: map['action'] as String,
      value: map['value'] != null ? (map['value'] as num).toDouble() : null,
      scheduleType: map['schedule_type'] as String,
      scheduleTime: map['schedule_time'] as String?,
      weekDays: map['week_days'] != null
          ? (map['week_days'] as String).split(',').map((e) => int.parse(e)).toList()
          : null,
      scheduledDate: map['scheduled_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['scheduled_date'] as int)
          : null,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      lastExecuted: map['last_executed'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_executed'] as int)
          : null,
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_name': taskName,
      'actuator_id': actuatorId,
      'action': action,
      'value': value,
      'schedule_type': scheduleType,
      'schedule_time': scheduleTime,
      'week_days': weekDays?.join(','),
      'scheduled_date': scheduledDate?.millisecondsSinceEpoch,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'last_executed': lastExecuted?.millisecondsSinceEpoch,
    };
  }
}






