import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../providers/sensor_provider.dart';
import '../providers/alert_provider.dart';
import '../services/voice_service.dart';
import '../services/firebase_service.dart';
import '../widgets/voice_button.dart';
import 'sensor_monitoring_screen.dart';
import 'control_panel_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import 'alerts_screen.dart';
import 'beacon_landing_screen.dart';
import 'resource_sharing_screen.dart';
import 'profile_screen.dart';
import 'beacon_landing_screen.dart';
import 'resource_sharing_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  bool isAutoMode = true;
  final int _selectedIndex = 0;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  
  // Voice
  final VoiceService _voiceService = VoiceService();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isListening = false;
  String _recognizedText = '';
  
  // Actuator states for quick controls
  bool _pumpState = false;
  bool _lightsState = false;
  bool _fanState = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _initVoice();
    _loadActuatorStates();
    _loadSystemMode();
  }
  
  Future<void> _loadSystemMode() async {
    try {
      final mode = await _firebaseService.getSystemMode();
      if (mounted && mode != null) {
        setState(() {
          isAutoMode = mode;
        });
      }
    } catch (e) {
      debugPrint('DashboardScreen: Error loading system mode: $e');
    }
  }
  
  Future<void> _loadActuatorStates() async {
    try {
      final states = await _firebaseService.getAllActuatorStates();
      if (mounted) {
        setState(() {
          _pumpState = states['pump'] ?? false;
          _lightsState = states['lights'] ?? false;
          _fanState = states['fan'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('DashboardScreen: Error loading actuator states: $e');
    }
  }
  
  Future<void> _toggleQuickActuator(String actuatorId, bool currentState) async {
    try {
      final newState = !currentState;
      debugPrint('DashboardScreen: Toggling $actuatorId from $currentState to $newState');
      
      // Update local state immediately for UI responsiveness
      if (mounted) {
        setState(() {
          switch (actuatorId) {
            case 'pump':
              _pumpState = newState;
              break;
            case 'lights':
              _lightsState = newState;
              break;
            case 'fan':
              _fanState = newState;
              break;
          }
        });
      }
      
      // Send to Firebase
      await _firebaseService.setActuatorState(actuatorId, newState);
      debugPrint('DashboardScreen: Successfully toggled $actuatorId to $newState');
    } catch (e) {
      debugPrint('DashboardScreen: Error toggling actuator $actuatorId: $e');
      // Revert on error
      if (mounted) {
        setState(() {
          switch (actuatorId) {
            case 'pump':
              _pumpState = currentState;
              break;
            case 'lights':
              _lightsState = currentState;
              break;
            case 'fan':
              _fanState = currentState;
              break;
          }
        });
      }
    }
  }
  
  void _initVoice() {
    _voiceService.initialize();
    
    _voiceService.onListeningChanged = (isListening) {
      if (mounted) setState(() => _isListening = isListening);
    };
    
    _voiceService.onWordsRecognized = (text) {
      if (mounted) setState(() => _recognizedText = text);
    };
    
    _voiceService.onCommandRecognized = (command, text) {
      _handleVoiceCommand(command);
    };
    
    _voiceService.onActuatorCommand = (actuatorId, turnOn) async {
      try {
        await _firebaseService.setActuatorState(actuatorId, turnOn);
        debugPrint('Voice command: Actuator $actuatorId set to ${turnOn ? "ON" : "OFF"} via Firebase');
        
        // Update local state immediately to reflect the change in quick controls
        if (mounted) {
          setState(() {
            switch (actuatorId) {
              case 'pump':
                _pumpState = turnOn;
                break;
              case 'lights':
                _lightsState = turnOn;
                break;
              case 'fan':
                _fanState = turnOn;
                break;
            }
          });
        }
        
        // Also reload states from Firebase after a short delay to ensure sync
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _loadActuatorStates();
          }
        });
      } catch (e) {
        debugPrint('Error sending voice actuator command: $e');
      }
    };
  }
  
  void _handleVoiceCommand(VoiceCommand command) {
    final sensorProvider = context.read<SensorProvider>();
    final alertProvider = context.read<AlertProvider>();
    
    switch (command) {
      case VoiceCommand.status:
        _voiceService.speakSystemStatus(sensorProvider.getAllSensors());
        break;
      case VoiceCommand.temperature:
        if (sensorProvider.temperature != null) {
          _voiceService.speakSensor(sensorProvider.temperature!);
        }
        break;
      case VoiceCommand.waterLevel:
        if (sensorProvider.waterLevel != null) {
          _voiceService.speakSensor(sensorProvider.waterLevel!);
        }
        break;
      case VoiceCommand.pH:
        if (sensorProvider.pH != null) {
          _voiceService.speakSensor(sensorProvider.pH!);
        }
        break;
      case VoiceCommand.tds:
        if (sensorProvider.tds != null) {
          _voiceService.speakSensor(sensorProvider.tds!);
        }
        break;
      case VoiceCommand.light:
        if (sensorProvider.light != null) {
          _voiceService.speakSensor(sensorProvider.light!);
        }
        break;
      case VoiceCommand.alerts:
        // Speak alerts summary and navigate to alerts screen
        _voiceService.speakAlertsSummary(alertProvider.alerts);
        // Navigate to alerts screen after TTS starts
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted && context.mounted) {
            try {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AlertsScreen()),
              ).then((_) {
                if (mounted) {
                  alertProvider.refresh();
                }
              });
            } catch (e) {
              debugPrint('DashboardScreen: Error navigating to alerts: $e');
            }
          }
        });
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _navigateToScreen(int index) {
    if (index == 0) return;
    
    Widget screen;
    switch (index) {
      case 1:
        screen = const SensorMonitoringScreen();
        break;
      case 2:
        screen = const ControlPanelScreen();
        break;
      case 3:
        screen = const AnalyticsScreen();
        break;
      case 4:
        screen = const SettingsScreen();
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF006064),
                  Color(0xFF00838F),
                  Color(0xFFF5F5F5),
                ],
                stops: [0.0, 0.3, 0.3],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await context.read<SensorProvider>().refresh();
                      await _loadActuatorStates();
                    },
                    color: const Color(0xFF00BCD4),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          _buildStatusBanner(),
                          const SizedBox(height: 20),
                          _build3DSystemView(),
                          const SizedBox(height: 24),
                          _buildSensorGrid(),
                          const SizedBox(height: 24),
                          _buildQuickActions(),
                          const SizedBox(height: 24),
                          _buildBeaconCard(),
                          const SizedBox(height: 24),
                          _buildRecentAlerts(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Voice button overlay
          Positioned(
            right: 16,
            bottom: 100,
            child: VoiceButton(
              isListening: _isListening,
              recognizedText: _recognizedText,
              onPressed: () => _voiceService.toggleListening(),
              onLongPress: () {
                // Read full status on long press
                final sensors = context.read<SensorProvider>().getAllSensors();
                _voiceService.speakSystemStatus(sensors);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBlobNavigationBar(),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AquaGrow',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Smart Hydroponic System',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Consumer<AlertProvider>(
                builder: (context, alertProvider, child) {
                  final count = alertProvider.unreadCount;
                  return _buildGlassIconButton(
                    icon: Icons.notifications_outlined,
                    badge: count > 0 ? (count > 9 ? '9+' : count.toString()) : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AlertsScreen()),
                      ).then((_) => alertProvider.refresh());
                    },
                  );
                },
              ),
              const SizedBox(width: 12),
              _buildGlassIconButton(
                icon: Icons.settings_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Stack(
      children: [
        ClipRRect(
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
        ),
        if (badge != null)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7043),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF7043).withValues(alpha: 0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Consumer<SensorProvider>(
                      builder: (context, provider, child) {
                        return AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: provider.isConnected
                                    ? const Color(0xFF7CB342)
                                    : Colors.grey,
                                shape: BoxShape.circle,
                                boxShadow: provider.isConnected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF7CB342).withValues(
                                            alpha: _pulseController.value,
                                          ),
                                          blurRadius: 10 * _pulseController.value,
                                          spreadRadius: 3 * _pulseController.value,
                                        ),
                                      ]
                                    : null,
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Consumer<SensorProvider>(
                      builder: (context, provider, child) {
                        return Text(
                          provider.isConnected ? 'System Active' : 'Offline',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Speaker button for TTS
                    GestureDetector(
                      onTap: () async {
                        try {
                          final sensors = context.read<SensorProvider>().getAllSensors();
                          await _voiceService.speakSystemStatus(sensors);
                          debugPrint('DashboardScreen: TTS triggered via speaker button');
                        } catch (e) {
                          debugPrint('DashboardScreen: Error with speaker button TTS: $e');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.volume_up,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isAutoMode ? 'Auto' : 'Manual',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final newMode = !isAutoMode;
                        setState(() {
                          isAutoMode = newMode;
                        });
                        // Save to Firebase
                        try {
                          await _firebaseService.setSystemMode(newMode);
                        } catch (e) {
                          debugPrint('DashboardScreen: Error saving system mode: $e');
                        }
                      },
                      child: Container(
                        width: 50,
                        height: 28,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            colors: isAutoMode
                                ? [const Color(0xFF00BCD4), const Color(0xFF7CB342)]
                                : [Colors.grey, Colors.grey[700]!],
                          ),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 200),
                          alignment: isAutoMode
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            width: 24,
                            height: 24,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _build3DSystemView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF006064).withValues(alpha: 0.3),
              const Color(0xFF00BCD4).withValues(alpha: 0.2),
            ],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: FlowLinesPainter(
                        animationValue: _waveController.value,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.water_drop,
                        size: 60,
                        color: Color(0xFF00BCD4),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '3D System View',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tap to rotate & explore',
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
          ),
        ),
      ),
    );
  }

  // ✨ UPDATED: Now reads from Firebase
  Widget _buildSensorGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Environmental Data',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Consumer<SensorProvider>(
                builder: (context, provider, child) {
                  return Row(
                    children: [
                      Icon(
                        provider.isConnected ? Icons.cloud_done : Icons.cloud_off,
                        size: 16,
                        color: provider.isConnected ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        provider.isConnected
                            ? 'Live • ${provider.timeSinceUpdate}'
                            : 'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          color: provider.isConnected ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Consumer<SensorProvider>(
            builder: (context, sensorProvider, child) {
              // Loading state
              if (sensorProvider.isLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFF00BCD4),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading sensor data...',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Error state
              if (sensorProvider.error != null) {
                return Center(
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Error loading sensors',
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sensorProvider.error!,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => sensorProvider.refresh(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BCD4),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final sensors = sensorProvider.getAllSensors();
              
              // Empty state
              if (sensors.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.sensors_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No sensor data available',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Make sure Wokwi simulator is running',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Display sensors from Firebase
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.95,
                ),
                itemCount: sensors.length,
                itemBuilder: (context, index) {
                  final sensor = sensors[index];
                  return _buildLiquidSensorCard(
                    icon: sensor.icon,
                    label: sensor.displayName,
                    value: sensor.displayValue,
                    unit: sensor.unit,
                    progress: sensor.progress,
                    color: sensor.sensorColor,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLiquidSensorCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required double progress,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: LiquidFillPainter(
                    progress: progress,
                    color: color,
                    animationValue: _waveController.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const Spacer(),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          unit,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Control',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBlobActionButton(
                icon: Icons.water_drop,
                label: 'Pump',
                isActive: _pumpState,
                color: const Color(0xFF00BCD4),
                onTap: () => _toggleQuickActuator('pump', _pumpState),
              ),
              _buildBlobActionButton(
                icon: Icons.lightbulb_outline,
                label: 'Lights',
                isActive: _lightsState,
                color: const Color(0xFFFFA726),
                onTap: () => _toggleQuickActuator('lights', _lightsState),
              ),
              _buildBlobActionButton(
                icon: Icons.air,
                label: 'Fan',
                isActive: _fanState,
                color: const Color(0xFF66BB6A),
                onTap: () => _toggleQuickActuator('fan', _fanState),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBlobActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isActive
                  ? RadialGradient(
                      colors: [
                        color,
                        color.withValues(alpha: 0.7),
                      ],
                    )
                  : null,
              color: isActive ? null : Colors.grey[300],
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              size: 36,
              color: isActive ? Colors.white : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.black87 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAlerts() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Alerts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  final alertProvider = context.read<AlertProvider>();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AlertsScreen()),
                  ).then((_) => alertProvider.refresh());
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Consumer<AlertProvider>(
            builder: (context, alertProvider, child) {
              final alerts = alertProvider.alerts.take(3).toList();
              
              if (alerts.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7CB342).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          color: Color(0xFF7CB342),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'All Clear',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'No alerts at the moment',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return Column(
                children: alerts.map((alert) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildAlertBubble(
                      icon: alert.icon,
                      title: alert.title,
                      subtitle: alert.message,
                      time: alert.timeAgo,
                      color: alert.color,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBubble({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
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
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlobNavigationBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.dashboard, 'Home', 0),
          _buildNavItem(Icons.sensors, 'Sensors', 1),
          _buildNavItem(Icons.settings_remote, 'Control', 2),
          _buildNavItem(Icons.analytics, 'Analytics', 3),
          _buildNavItem(Icons.settings, 'Settings', 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (index != _selectedIndex) {
          _navigateToScreen(index);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00BCD4).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF00BCD4) : Colors.grey,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? const Color(0xFF00BCD4) : Colors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painters (unchanged)
class FlowLinesPainter extends CustomPainter {
  final double animationValue;

  FlowLinesPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan.withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final waveHeight = 20.0;
    final waveLength = size.width / 3;

    path.moveTo(0, size.height / 2);

    for (double x = 0; x <= size.width; x++) {
      final y = size.height / 2 +
          math.sin((x / waveLength) * 2 * math.pi + animationValue * 2 * math.pi) *
              waveHeight;
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);

    final particlePaint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final x = (size.width * ((i * 0.2 + animationValue) % 1));
      final y = size.height / 2 +
          math.sin((x / waveLength) * 2 * math.pi) * waveHeight;
      canvas.drawCircle(Offset(x, y), 4, particlePaint);
    }
  }

  @override
  bool shouldRepaint(FlowLinesPainter oldDelegate) => true;
}

class LiquidFillPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double animationValue;

  LiquidFillPainter({
    required this.progress,
    required this.color,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = 8.0;
    final baseY = size.height * (1 - progress);

    path.moveTo(0, size.height);
    path.lineTo(0, baseY);

    for (double x = 0; x <= size.width; x++) {
      final y = baseY +
          math.sin((x / size.width) * 4 * math.pi + animationValue * 2 * math.pi) *
              waveHeight;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(LiquidFillPainter oldDelegate) => true;
}
