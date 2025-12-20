import 'package:flutter/material.dart';
import '../models/sensor_reading.dart';
import '../models/sensor_activity.dart';
import '../services/firebase_service.dart';
import '../services/database_service.dart';
import 'dart:async';

class SensorProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final DatabaseService _databaseService = DatabaseService();
  
  Map<String, SensorReading> _sensors = {};
  bool _isLoading = true;
  bool _isConnected = false;
  String? _error;
  DateTime? _lastUpdate;
  
  // Callback for alert checking (set by AlertProvider)
  Function(List<SensorReading>)? onSensorUpdate;
  
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
          (data) async {
            _sensors = data;
            _isLoading = false;
            _lastUpdate = DateTime.now();
            _error = null;
            
            // Save to SQLite database
            await _saveSensorReadingsToDatabase(data);
            
            // Store sensor activity in SQLite (throttled)
            _logSensorActivity(data.values.toList());
            
            // Trigger alert check callback
            onSensorUpdate?.call(data.values.toList());
            
            notifyListeners();
          },
          onError: (error) {
            _error = error.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
    
    // Load cached data from SQLite if Firebase is not connected
    _loadCachedSensorReadings();
  }

  /// Save sensor readings to SQLite database
  Future<void> _saveSensorReadingsToDatabase(Map<String, SensorReading> sensors) async {
    try {
      for (var reading in sensors.values) {
        await _databaseService.insertSensorReading(reading);
      }
    } catch (e) {
      debugPrint('Error saving sensor readings to database: $e');
    }
  }

  /// Load cached sensor readings from SQLite
  Future<void> _loadCachedSensorReadings() async {
    try {
      // Load latest readings for each sensor type
      final sensorTypes = ['temperature', 'waterLevel', 'pH', 'tds', 'light'];
      Map<String, SensorReading> cachedSensors = {};
      
      for (var sensorId in sensorTypes) {
        final reading = await _databaseService.getLatestSensorReading(sensorId);
        if (reading != null) {
          cachedSensors[sensorId] = reading;
        }
      }
      
      if (cachedSensors.isNotEmpty && _sensors.isEmpty) {
        _sensors = cachedSensors;
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cached sensor readings: $e');
    }
  }
  
  // Log sensor readings to SQLite (throttled to once per minute)
  DateTime? _lastLogTime;
  Future<void> _logSensorActivity(List<SensorReading> sensors) async {
    if (_lastLogTime != null &&
        DateTime.now().difference(_lastLogTime!) < const Duration(minutes: 1)) {
      return;
    }
    _lastLogTime = DateTime.now();
    
    for (final sensor in sensors) {
      try {
        await _databaseService.insertSensorActivity(SensorActivity(
          sensorId: sensor.id,
          sensorName: sensor.displayName,
          value: sensor.value,
          unit: sensor.unit,
          status: sensor.status,
          timestamp: DateTime.now(),
        ));
      } catch (e) {
        debugPrint('Error logging sensor activity: $e');
      }
    }
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
    
    // Try to load from cache if Firebase is not connected
    if (!_isConnected) {
      await _loadCachedSensorReadings();
    }
    
    await Future.delayed(const Duration(milliseconds: 500));
    _isLoading = false;
    notifyListeners();
  }

  // Get historical sensor readings from database
  Future<List<SensorReading>> getHistoricalReadings(
    String sensorId, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    return await _databaseService.getSensorReadings(
      sensorId,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }
}
