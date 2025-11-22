import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';
import 'package:provider/provider.dart';
import '../providers/sensor_provider.dart';

class SensorMonitoringScreen extends StatefulWidget {
  const SensorMonitoringScreen({super.key});

  @override
  State<SensorMonitoringScreen> createState() => _SensorMonitoringScreenState();
}

class _SensorMonitoringScreenState extends State<SensorMonitoringScreen>
    with TickerProviderStateMixin {
  bool autoUpdate = true;
  late AnimationController _waveController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
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
                child: RefreshIndicator(
                  onRefresh: () async {
                    await context.read<SensorProvider>().refresh();
                  },
                  color: Color(0xFF00BCD4),
                  child: Consumer<SensorProvider>(
                    builder: (context, sensorProvider, child) {
                      // Loading state
                      if (sensorProvider.isLoading) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: Color(0xFF00BCD4),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Loading sensors...',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Error state
                      if (sensorProvider.error != null) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, 
                                  size: 64, 
                                  color: Colors.white70
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Error loading sensors',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  sensorProvider.error!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () => sensorProvider.refresh(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF00BCD4),
                                  ),
                                  child: Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final sensors = sensorProvider.getAllSensors();

                      // Empty state
                      if (sensors.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.sensors_off, 
                                  size: 64, 
                                  color: Colors.white70
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No sensor data available',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Make sure Wokwi simulator is running',
                                  style: TextStyle(
                                    fontSize: 14, 
                                    color: Colors.white70
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Display sensors
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: sensors.length,
                        itemBuilder: (context, index) {
                          final sensor = sensors[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: _buildLiquidSensorCard(
                              SensorData(
                                name: sensor.displayName,
                                icon: sensor.icon,
                                value: sensor.value,
                                unit: sensor.unit,
                                min: sensor.min,
                                max: sensor.max,
                                avg: sensor.value,
                                color: sensor.sensorColor,
                                optimal: sensor.status == 'optimal' || 
                                        sensor.status == 'good',
                              ),
                            ),
                          );
                        },
                      );
                    },
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
                  'Sensor Monitoring',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Consumer<SensorProvider>(
                  builder: (context, provider, child) {
                    return Text(
                      provider.isConnected 
                          ? 'Real-time data stream • ${provider.timeSinceUpdate}'
                          : 'Disconnected',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          _buildGlassIconButton(
            icon: Icons.refresh,
            onTap: () {
              context.read<SensorProvider>().refresh();
            },
          ),
          const SizedBox(width: 8),
          _buildAutoUpdateToggle(),
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

  Widget _buildAutoUpdateToggle() {
    return GestureDetector(
      onTap: () {
        setState(() {
          autoUpdate = !autoUpdate;
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  autoUpdate ? Icons.sync : Icons.sync_disabled,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Auto',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiquidSensorCard(SensorData sensor) {
    final progress = (sensor.value - sensor.min) / (sensor.max - sensor.min);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: sensor.color.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  sensor.color.withValues(alpha: 0.1),
                  sensor.color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: sensor.color.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(sensor.icon, color: sensor.color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sensor.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Color(0xFF7CB342),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF7CB342).withValues(
                                        alpha: _pulseController.value,
                                      ),
                                      blurRadius: 8 * _pulseController.value,
                                      spreadRadius: 2 * _pulseController.value,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Live Data',
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: sensor.optimal
                        ? Color(0xFF7CB342).withValues(alpha: 0.1)
                        : Color(0xFFFF5252).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    sensor.optimal ? 'Optimal' : 'Warning',
                    style: TextStyle(
                      color: sensor.optimal
                          ? Color(0xFF7CB342)
                          : Color(0xFFFF5252),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Value display with liquid gauge
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Value
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Reading',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            sensor.value.toStringAsFixed(
                              sensor.name.contains('pH') || 
                              sensor.name.contains('Temp') ? 1 : 0
                            ),
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              sensor.unit,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Liquid circular gauge
                SizedBox(
                  width: 100,
                  height: 100,
                  child: LiquidCircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    valueColor: AlwaysStoppedAnimation(sensor.color),
                    backgroundColor: Colors.grey[200]!,
                    borderColor: sensor.color,
                    borderWidth: 3.0,
                    direction: Axis.vertical,
                    center: Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Mini chart placeholder with wave
          Container(
            height: 80,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: sensor.color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: MiniChartPainter(
                    color: sensor.color,
                    animationValue: _waveController.value,
                  ),
                  child: Center(
                    child: Text(
                      '24-Hour Trend',
                      style: TextStyle(
                        color: sensor.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Statistics
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Min', 
                  sensor.min.toStringAsFixed(
                    sensor.name.contains('pH') || 
                    sensor.name.contains('Temp') ? 1 : 0
                  ), 
                  sensor.unit
                ),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                _buildStatItem(
                  'Avg', 
                  sensor.avg.toStringAsFixed(
                    sensor.name.contains('pH') || 
                    sensor.name.contains('Temp') ? 1 : 0
                  ), 
                  sensor.unit
                ),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                _buildStatItem(
                  'Max', 
                  sensor.max.toStringAsFixed(
                    sensor.name.contains('pH') || 
                    sensor.name.contains('Temp') ? 1 : 0
                  ), 
                  sensor.unit
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.history,
                    label: 'History',
                    color: sensor.color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.tune,
                    label: 'Calibrate',
                    color: sensor.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$value$unit',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SensorData {
  final String name;
  final IconData icon;
  final double value;
  final String unit;
  final double min;
  final double max;
  final double avg;
  final Color color;
  final bool optimal;

  SensorData({
    required this.name,
    required this.icon,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.avg,
    required this.color,
    required this.optimal,
  });
}

class MiniChartPainter extends CustomPainter {
  final Color color;
  final double animationValue;

  MiniChartPainter({required this.color, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final points = 20;

    for (int i = 0; i < points; i++) {
      final x = (size.width / points) * i;
      final y = size.height / 2 +
          math.sin((i / points) * 4 * math.pi + animationValue * 2 * math.pi) *
              (size.height / 4);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(MiniChartPainter oldDelegate) => true;
}
