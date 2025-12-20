import 'package:flutter/material.dart';
import 'dart:ui';

class ControlPanelScreen extends StatefulWidget {
  const ControlPanelScreen({super.key});

  @override
  State<ControlPanelScreen> createState() => _ControlPanelScreenState();
}

class _ControlPanelScreenState extends State<ControlPanelScreen>
    with TickerProviderStateMixin {
  late AnimationController _flowController;
  late AnimationController _splashController;

  final List<ActuatorData> actuators = [
    ActuatorData(
      name: 'Water Pump',
      icon: Icons.water_drop,
      isActive: true,
      color: const Color(0xFF00BCD4),
      runtime: '4h 23m',
    ),
    ActuatorData(
      name: 'LED Grow Lights',
      icon: Icons.lightbulb,
      isActive: true,
      color: const Color(0xFFFFA726),
      runtime: '12h 45m',
    ),
    ActuatorData(
      name: 'Cooling Fan',
      icon: Icons.air,
      isActive: false,
      color: const Color(0xFF66BB6A),
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF006064),
              Color(0xFFF5F5F5),
            ],
            stops: [0.0, 0.25],
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
          const Expanded(
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
          const Positioned(
            top: 16,
            left: 20,
            child: Text(
              'System Flow Diagram',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
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
        const Text(
          'Actuator Controls',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: actuator.isActive
                ? actuator.color.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                  onTap: () {
                    _splashController.forward(from: 0);
                    setState(() {
                      actuator.isActive = !actuator.isActive;
                    });
                  },
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
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
                                  ? const Color(0xFF7CB342)
                                  : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            actuator.isActive ? 'Running' : 'Stopped',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.access_time, size: 12, color: Colors.black54),
                          const SizedBox(width: 4),
                          Text(
                            actuator.runtime,
                            style: const TextStyle(
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
                  onTap: () {
                    _splashController.forward(from: 0);
                    setState(() {
                      actuator.isActive = !actuator.isActive;
                    });
                  },
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
                      duration: const Duration(milliseconds: 200),
                      alignment: actuator.isActive
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
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
              onTap: () {},
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
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
        const Text(
          'Scheduled Tasks',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildScheduleItem(
                icon: Icons.water_drop,
                title: 'Water Pump Schedule',
                subtitle: 'Every 2 hours, 10 min duration',
                isActive: true,
                color: const Color(0xFF00BCD4),
              ),
              const Divider(height: 1),
              _buildScheduleItem(
                icon: Icons.lightbulb,
                title: 'Lighting Schedule',
                subtitle: '6:00 AM - 10:00 PM daily',
                isActive: true,
                color: const Color(0xFFFFA726),
              ),
              const Divider(height: 1),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, color: Color(0xFF00BCD4)),
                        SizedBox(width: 8),
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

  Widget _buildScheduleItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isActive,
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
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            onChanged: (value) {},
            activeThumbColor: color,
          ),
        ],
      ),
    );
  }

  Widget _buildControlHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Control History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHistoryItem(
                icon: Icons.water_drop,
                title: 'Pump turned ON',
                time: '2 hours ago',
                type: 'Manual',
                color: const Color(0xFF00BCD4),
              ),
              const Divider(height: 1),
              _buildHistoryItem(
                icon: Icons.lightbulb,
                title: 'Lights turned OFF',
                time: '5 hours ago',
                type: 'Scheduled',
                color: const Color(0xFFFFA726),
              ),
              const Divider(height: 1),
              _buildHistoryItem(
                icon: Icons.air,
                title: 'Fan turned ON',
                time: '8 hours ago',
                type: 'Auto',
                color: const Color(0xFF66BB6A),
              ),
            ],
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
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
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black87,
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
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5252), Color(0xFFD32F2F)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5252).withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.stop_circle, color: Colors.white, size: 28),
              SizedBox(width: 12),
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
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252), size: 28),
          SizedBox(width: 12),
          Text('Emergency Stop'),
        ],
      ),
      content: const Text(
        'Are you sure you want to stop all actuators?\n\nThis will immediately halt all operations.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            // Stop all actuators
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5252),
          ),
          child: const Text('Stop All'),
        ),
      ],
    );
  }
}

class ActuatorData {
  String name;
  IconData icon;
  bool isActive;
  Color color;
  String runtime;

  ActuatorData({
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
