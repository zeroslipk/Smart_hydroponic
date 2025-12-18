import 'package:flutter/material.dart';
import '../models/scheduled_task.dart';
import '../models/actuator_activity.dart';
import '../services/database_service.dart';

class ActuatorData {
  String id;
  String name;
  IconData icon;
  bool isActive;
  Color color;
  String runtime;

  ActuatorData({
    required this.id,
    required this.name,
    required this.icon,
    required this.isActive,
    required this.color,
    required this.runtime,
  });
}

class ControlPanelViewModel extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  
  List<ScheduledTask> _scheduledTasks = [];
  List<ActuatorActivity> _controlHistory = [];
  bool _isLoading = false;
  
  final List<ActuatorData> _actuators = [
    ActuatorData(
      id: 'pump',
      name: 'Water Pump',
      icon: Icons.water_drop,
      isActive: true,
      color: const Color(0xFF00BCD4),
      runtime: '4h 23m',
    ),
    ActuatorData(
      id: 'lights',
      name: 'LED Grow Lights',
      icon: Icons.lightbulb,
      isActive: true,
      color: const Color(0xFFFFA726),
      runtime: '12h 45m',
    ),
    ActuatorData(
      id: 'fan',
      name: 'Cooling Fan',
      icon: Icons.air,
      isActive: false,
      color: const Color(0xFF66BB6A),
      runtime: '0h 0m',
    ),
  ];
  
  // Getters
  List<ActuatorData> get actuators => _actuators;
  List<ScheduledTask> get scheduledTasks => _scheduledTasks;
  List<ActuatorActivity> get controlHistory => _controlHistory;
  bool get isLoading => _isLoading;
  
  ControlPanelViewModel() {
    loadData();
  }
  
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    
    _scheduledTasks = await _db.getScheduledTasks();
    _controlHistory = await _db.getActuatorActivities(limit: 10);
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> toggleActuator(ActuatorData actuator) async {
    actuator.isActive = !actuator.isActive;
    notifyListeners();
    
    await _db.insertActuatorActivity(ActuatorActivity(
      actuatorId: actuator.id,
      actuatorName: actuator.name,
      isOn: actuator.isActive,
      actionType: ActuatorActionType.manual,
      timestamp: DateTime.now(),
    ));
    
    await loadData();
  }
  
  Future<void> toggleScheduledTask(int taskId, bool enabled) async {
    await _db.toggleScheduledTask(taskId, enabled);
    await loadData();
  }
  
  Future<void> createSchedule({
    required String actuatorId,
    required String actuatorName,
    required String scheduleType,
    int? intervalMinutes,
    String? startTime,
    String? endTime,
    required int durationMinutes,
  }) async {
    await _db.insertScheduledTask(ScheduledTask(
      actuatorId: actuatorId,
      actuatorName: actuatorName,
      scheduleType: scheduleType,
      intervalMinutes: intervalMinutes,
      startTime: startTime,
      endTime: endTime,
      durationMinutes: durationMinutes,
      createdAt: DateTime.now(),
    ));
    await loadData();
  }
  
  Map<String, String> get actuatorNames => {
    'pump': 'Water Pump',
    'lights': 'LED Grow Lights',
    'fan': 'Cooling Fan',
  };
}
