import 'package:flutter/material.dart';
import '../models/sensor_reading.dart';
import '../providers/sensor_provider.dart';
import '../providers/alert_provider.dart';
import '../services/voice_service.dart';

class DashboardViewModel extends ChangeNotifier {
  final SensorProvider sensorProvider;
  final AlertProvider alertProvider;
  final VoiceService _voiceService = VoiceService();
  
  int _currentNavIndex = 0;
  bool _isVoiceListening = false;
  String _recognizedWords = '';
  
  DashboardViewModel({
    required this.sensorProvider,
    required this.alertProvider,
  }) {
    _initVoiceService();
  }
  
  // Getters
  int get currentNavIndex => _currentNavIndex;
  bool get isVoiceListening => _isVoiceListening;
  String get recognizedWords => _recognizedWords;
  VoiceService get voiceService => _voiceService;
  
  List<SensorReading> get sensors => sensorProvider.getAllSensors();
  bool get isConnected => sensorProvider.isConnected;
  int get unreadAlertCount => alertProvider.unreadCount;
  
  // Navigation
  void setNavIndex(int index) {
    _currentNavIndex = index;
    notifyListeners();
  }
  
  // Voice Service
  void _initVoiceService() {
    _voiceService.initialize();
    
    _voiceService.onListeningChanged = (isListening) {
      _isVoiceListening = isListening;
      notifyListeners();
    };
    
    _voiceService.onWordsRecognized = (words) {
      _recognizedWords = words;
      notifyListeners();
    };
    
    _voiceService.onCommandRecognized = (command, words) {
      handleVoiceCommand(command);
    };
  }
  
  void toggleVoiceListening() {
    _voiceService.toggleListening();
  }
  
  void handleVoiceCommand(VoiceCommand command) {
    final sensors = sensorProvider.getAllSensors();
    
    switch (command) {
      case VoiceCommand.status:
        final statusText = 'System ${isConnected ? "online" : "offline"} with ${sensors.length} sensors. ${alertProvider.unreadCount} unread alerts.';
        _voiceService.speak(statusText);
        break;
      case VoiceCommand.temperature:
        final temp = sensors.firstWhere(
          (s) => s.id == 'temperature',
          orElse: () => SensorReading(id: 'temperature', value: 0, unit: '°C', status: 'unknown', min: 0, max: 0, timestamp: DateTime.now()),
        );
        _voiceService.speakSensor(temp);
        break;
      case VoiceCommand.pH:
        final ph = sensors.firstWhere(
          (s) => s.id == 'pH',
          orElse: () => SensorReading(id: 'pH', value: 0, unit: '', status: 'unknown', min: 0, max: 0, timestamp: DateTime.now()),
        );
        _voiceService.speakSensor(ph);
        break;
      case VoiceCommand.alerts:
        _voiceService.speakAlertsSummary(alertProvider.alerts.take(3).toList());
        break;
      default:
        break;
    }
  }
  
  void speakSystemStatus() {
    final statusText = 'System ${isConnected ? "online" : "offline"} with ${sensors.length} sensors. ${alertProvider.unreadCount} unread alerts.';
    _voiceService.speak(statusText);
  }
  
}
