import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/database_service.dart';
import '../services/firebase_service.dart';
import '../models/scheduled_task.dart';
import '../models/actuator_activity.dart';

class ControlPanelScreen extends StatefulWidget {
  const ControlPanelScreen({super.key});

  @override
  State<ControlPanelScreen> createState() => _ControlPanelScreenState();
}

class _ControlPanelScreenState extends State<ControlPanelScreen>
    with TickerProviderStateMixin {
  late AnimationController _flowController;
  late AnimationController _splashController;
  
  final DatabaseService _db = DatabaseService();
  final FirebaseService _firebaseService = FirebaseService();
  List<ScheduledTask> _scheduledTasks = [];
  List<ActuatorActivity> _controlHistory = [];

  final List<ActuatorData> actuators = [
    ActuatorData(
      id: 'pump',
      name: 'Water Pump',
      icon: Icons.water_drop,
      isActive: false, // Will be synced from Firebase
      color: Color(0xFF00BCD4),
      runtime: '4h 23m',
    ),
    ActuatorData(
      id: 'lights',
      name: 'LED Grow Lights',
      icon: Icons.lightbulb,
      isActive: false, // Will be synced from Firebase
      color: Color(0xFFFFA726),
      runtime: '12h 45m',
    ),
    ActuatorData(
      id: 'fan',
      name: 'Cooling Fan',
      icon: Icons.air,
      isActive: false, // Will be synced from Firebase
      color: Color(0xFF66BB6A),
      runtime: '0h 0m',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _flowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _splashController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _loadData();
  }
  
  Future<void> _loadData() async {
    final tasks = await _db.getScheduledTasks();
    final history = await _db.getActuatorActivities(limit: 10);
    
    // Load actuator states from Firebase
    await _loadActuatorStatesFromFirebase();
    
    setState(() {
      _scheduledTasks = tasks;
      _controlHistory = history;
    });
  }
  
  /// Load actuator states from Firebase to sync with hardware
  Future<void> _loadActuatorStatesFromFirebase() async {
    try {
      final states = await _firebaseService.getAllActuatorStates();
      debugPrint('ControlPanelScreen: Loading actuator states from Firebase: $states');
      
      for (final actuator in actuators) {
        if (states.containsKey(actuator.id)) {
          actuator.isActive = states[actuator.id] ?? false;
          debugPrint('ControlPanelScreen: Set ${actuator.id} to ${actuator.isActive}');
        }
      }
    } catch (e) {
      debugPrint('ControlPanelScreen: Error loading actuator states from Firebase: $e');
    }
  }
  
  Future<void> _toggleActuator(ActuatorData actuator) async {
    _splashController.forward(from: 0);
    final oldState = actuator.isActive;
    setState(() {
      actuator.isActive = !actuator.isActive;
    });
    
    try {
      debugPrint('ControlPanelScreen: Toggling ${actuator.id} from $oldState to ${actuator.isActive}');
      
      // Send command to Firebase (for hardware control)
      await _firebaseService.setActuatorState(actuator.id, actuator.isActive);
      
      debugPrint('ControlPanelScreen: Successfully sent ${actuator.id} state to Firebase');
      
      // Log to SQLite (for history)
      await _db.insertActuatorActivity(ActuatorActivity(
        actuatorId: actuator.id,
        actuatorName: actuator.name,
        isOn: actuator.isActive,
        actionType: ActuatorActionType.manual,
        timestamp: DateTime.now(),
      ));
      
      _loadData(); // Refresh history
    } catch (e, stackTrace) {
      debugPrint('ControlPanelScreen: ERROR toggling actuator: $e');
      debugPrint('ControlPanelScreen: Stack trace: $stackTrace');
      // Revert on error
      setState(() {
        actuator.isActive = oldState;
      });
    }
  }

  @override
  void dispose() {
    _flowController.dispose();
    _splashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.25],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFlowDiagram(),
                      const SizedBox(height: 24),
                      _buildActuatorsList(),
                      const SizedBox(height: 24),
                      _buildScheduledTasks(),
                      const SizedBox(height: 24),
                      _buildControlHistory(),
                      const SizedBox(height: 24),
                      _buildEmergencyStop(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildGlassIconButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Control Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Manage your actuators',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Icon(icon, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlowDiagram() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Animated flow lines
          AnimatedBuilder(
            animation: _flowController,
            builder: (context, child) {
              return CustomPaint(
                painter: CircuitFlowPainter(
                  animationValue: _flowController.value,
                  actuators: actuators,
                ),
                size: Size.infinite,
              );
            },
          ),
          // Title
          Positioned(
            top: 16,
            left: 20,
            child: Text(
              'System Flow Diagram',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActuatorsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actuator Controls',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        ...actuators.map((actuator) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildActuatorCard(actuator),
          );
        }),
      ],
    );
  }

  Widget _buildActuatorCard(ActuatorData actuator) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: actuator.isActive
                ? actuator.color.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon with splash effect
                GestureDetector(
                  onTap: () => _toggleActuator(actuator),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Splash animation
                      AnimatedBuilder(
                        animation: _splashController,
                        builder: (context, child) {
                          return Container(
                            width: 60 * (1 + _splashController.value * 0.5),
                            height: 60 * (1 + _splashController.value * 0.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: actuator.color.withValues(
                                alpha: 0.3 * (1 - _splashController.value),
                              ),
                            ),
                          );
                        },
                      ),
                      // Icon container
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: actuator.isActive
                              ? RadialGradient(
                                  colors: [
                                    actuator.color,
                                    actuator.color.withValues(alpha: 0.7),
                                  ],
                                )
                              : null,
                          color: actuator.isActive ? null : Colors.grey[300],
                          shape: BoxShape.circle,
                          boxShadow: actuator.isActive
                              ? [
                                  BoxShadow(
                                    color: actuator.color.withValues(alpha: 0.5),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          actuator.icon,
                          color: actuator.isActive
                              ? Colors.white
                              : Colors.grey[600],
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        actuator.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: actuator.isActive
                                  ? Color(0xFF7CB342)
                                  : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            actuator.isActive ? 'Running' : 'Stopped',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.access_time, size: 12, color: Colors.black54),
                          const SizedBox(width: 4),
                          Text(
                            actuator.runtime,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Toggle switch with liquid animation
                GestureDetector(
                  onTap: () => _toggleActuator(actuator),
                  child: Container(
                    width: 56,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: actuator.isActive
                          ? LinearGradient(
                              colors: [actuator.color, actuator.color.withValues(alpha: 0.7)],
                            )
                          : null,
                      color: actuator.isActive ? null : Colors.grey[300],
                    ),
                    child: AnimatedAlign(
                      duration: Duration(milliseconds: 200),
                      alignment: actuator.isActive
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, color: Colors.grey[200]),

          // Schedule button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showAddScheduleDialog(),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.schedule,
                      color: actuator.color,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Schedule ${actuator.name}',
                      style: TextStyle(
                        color: actuator.color,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledTasks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scheduled Tasks',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              if (_scheduledTasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.schedule, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        'No schedules yet',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              else
                ...List.generate(_scheduledTasks.length, (index) {
                  final task = _scheduledTasks[index];
                  return Column(
                    children: [
                      _buildScheduleItemFromTask(task),
                      if (index < _scheduledTasks.length - 1) const Divider(height: 1),
                    ],
                  );
                }),
              const Divider(height: 1),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showAddScheduleDialog(),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, color: Color(0xFF00BCD4)),
                        const SizedBox(width: 8),
                        Text(
                          'Add New Schedule',
                          style: TextStyle(
                            color: Color(0xFF00BCD4),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildScheduleItemFromTask(ScheduledTask task) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: task.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(task.icon, color: task.color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${task.actuatorName} Schedule',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  task.scheduleDescription,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: task.isEnabled,
            onChanged: (value) async {
              await _db.toggleScheduledTask(task.id!, value);
              _loadData();
            },
            activeThumbColor: task.color,
          ),
        ],
      ),
    );
  }
  
  void _showAddScheduleDialog() {
    String selectedActuator = 'pump';
    String scheduleType = 'interval';
    int intervalHours = 2;
    int durationMinutes = 10;
    TimeOfDay startTime = const TimeOfDay(hour: 6, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 22, minute: 0);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Add Schedule',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Actuator selection
                const Text('Select Actuator', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildChip('Pump', 'pump', selectedActuator, (v) => setModalState(() => selectedActuator = v)),
                    _buildChip('Lights', 'lights', selectedActuator, (v) => setModalState(() => selectedActuator = v)),
                    _buildChip('Fan', 'fan', selectedActuator, (v) => setModalState(() => selectedActuator = v)),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Schedule type
                const Text('Schedule Type', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildChip('Interval', 'interval', scheduleType, (v) => setModalState(() => scheduleType = v)),
                    _buildChip('Daily', 'daily', scheduleType, (v) => setModalState(() => scheduleType = v)),
                  ],
                ),
                const SizedBox(height: 20),
                
                if (scheduleType == 'interval') ...[
                  const Text('Run every', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: intervalHours.toDouble(),
                          min: 1,
                          max: 12,
                          divisions: 11,
                          label: '$intervalHours hours',
                          onChanged: (v) => setModalState(() => intervalHours = v.toInt()),
                        ),
                      ),
                      Text('$intervalHours hrs'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Duration', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: durationMinutes.toDouble(),
                          min: 1,
                          max: 60,
                          divisions: 59,
                          label: '$durationMinutes min',
                          onChanged: (v) => setModalState(() => durationMinutes = v.toInt()),
                        ),
                      ),
                      Text('$durationMinutes min'),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Start Time', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                final time = await showTimePicker(context: context, initialTime: startTime);
                                if (time != null) setModalState(() => startTime = time);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(startTime.format(context)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('End Time', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                final time = await showTimePicker(context: context, initialTime: endTime);
                                if (time != null) setModalState(() => endTime = time);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(endTime.format(context)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final actuatorNames = {'pump': 'Water Pump', 'lights': 'LED Grow Lights', 'fan': 'Cooling Fan'};
                      await _db.insertScheduledTask(ScheduledTask(
                        actuatorId: selectedActuator,
                        actuatorName: actuatorNames[selectedActuator]!,
                        scheduleType: scheduleType,
                        intervalMinutes: scheduleType == 'interval' ? intervalHours * 60 : null,
                        startTime: scheduleType == 'daily' ? '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}' : null,
                        endTime: scheduleType == 'daily' ? '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}' : null,
                        durationMinutes: durationMinutes,
                        createdAt: DateTime.now(),
                      ));
                      if (context.mounted) Navigator.pop(context);
                      _loadData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BCD4),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Create Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildChip(String label, String value, String selected, Function(String) onSelect) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00BCD4) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }


  Widget _buildControlHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Control History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: _controlHistory.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        'No activity yet',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Control actions will appear here',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: List.generate(_controlHistory.length, (index) {
                    final activity = _controlHistory[index];
                    return Column(
                      children: [
                        _buildHistoryItem(
                          icon: activity.icon,
                          title: activity.actionDescription,
                          time: activity.timeAgo,
                          type: activity.actionTypeLabel,
                          color: activity.color,
                        ),
                        if (index < _controlHistory.length - 1) const Divider(height: 1),
                      ],
                    );
                  }),
                ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem({
    required IconData icon,
    required String title,
    required String time,
    required String type,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              type,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyStop() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF5252), Color(0xFFD32F2F)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFF5252).withValues(alpha: 0.5),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => _buildEmergencyDialog(),
            );
          },
          borderRadius: BorderRadius.circular(30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.stop_circle, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                'EMERGENCY STOP ALL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252), size: 28),
          const SizedBox(width: 12),
          Text('Emergency Stop'),
        ],
      ),
      content: Text(
        'Are you sure you want to stop all actuators?\n\nThis will immediately halt all operations.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            // Stop all active actuators
            for (final actuator in actuators) {
              if (actuator.isActive) {
                _toggleActuator(actuator);
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFF5252),
          ),
          child: Text('Stop All'),
        ),
      ],
    );
  }
}

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

class CircuitFlowPainter extends CustomPainter {
  final double animationValue;
  final List<ActuatorData> actuators;

  CircuitFlowPainter({required this.animationValue, required this.actuators});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw connecting lines
    for (int i = 0; i < actuators.length; i++) {
      if (actuators[i].isActive) {
        paint.color = actuators[i].color.withValues(alpha: 0.5);

        final startX = size.width * 0.2;
        final endX = size.width * 0.8;
        final y = size.height * (0.3 + i * 0.2);

        // Draw line
        canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);

        // Draw flowing particles
        final particleX = startX + (endX - startX) * ((animationValue + i * 0.3) % 1);
        final particlePaint = Paint()
          ..color = actuators[i].color
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(particleX, y), 4, particlePaint);
      }
    }
  }

  @override
  bool shouldRepaint(CircuitFlowPainter oldDelegate) => true;
}
