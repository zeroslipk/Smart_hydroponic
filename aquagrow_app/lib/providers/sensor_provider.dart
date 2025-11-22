import 'package:flutter/material.dart';
import '../models/sensor_reading.dart';
import '../services/firebase_service.dart';
import 'dart:async';

class SensorProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  Map<String, SensorReading> _sensors = {};
  bool _isLoading = true;
  bool _isConnected = false;
  String? _error;
  DateTime? _lastUpdate;
  
  StreamSubscription? _sensorSubscription;
  StreamSubscription? _connectionSubscription;

  // Getters
  Map<String, SensorReading> get sensors => _sensors;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  String? get error => _error;
  DateTime? get lastUpdate => _lastUpdate;

  // Get time since last update
  String get timeSinceUpdate {
    if (_lastUpdate == null) return 'Never';
    final diff = DateTime.now().difference(_lastUpdate!);
    if (diff.inSeconds < 10) return 'Just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  SensorProvider() {
    _initialize();
  }

  void _initialize() {
    // Listen to connection status
    _connectionSubscription = _firebaseService
        .streamConnectionStatus()
        .listen((connected) {
      _isConnected = connected;
      notifyListeners();
    });

    // Listen to sensor data
    _sensorSubscription = _firebaseService
        .streamAllSensors()
        .listen(
          (data) {
            _sensors = data;
            _isLoading = false;
            _lastUpdate = DateTime.now();
            _error = null;
            notifyListeners();
          },
          onError: (error) {
            _error = error.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // Get specific sensor
  SensorReading? getSensor(String sensorId) => _sensors[sensorId];

  // Get all sensors as list
  List<SensorReading> getAllSensors() => _sensors.values.toList();

  // Convenience getters
  SensorReading? get temperature => _sensors['temperature'];
  SensorReading? get waterLevel => _sensors['waterLevel'];
  SensorReading? get pH => _sensors['pH'];
  SensorReading? get tds => _sensors['tds'];
  SensorReading? get light => _sensors['light'];

  // Refresh data
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }
}
