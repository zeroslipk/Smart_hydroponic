import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/sensor_reading.dart';
import 'dart:async';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  DatabaseReference get sensorsRef => _database.child('sensors');
  DatabaseReference get actuatorsRef => _database.child('controls');

  /// Map app actuator IDs to Firebase IDs
  String _getFirebaseActuatorId(String appId) {
    switch (appId) {
      case 'pump':
        return 'water_pump';
      case 'lights':
        return 'led_lights';
      case 'fan':
        return 'cooling_fan';
      default:
        return appId;
    }
  }

  /// Stream all sensor data in real-time
  Stream<Map<String, SensorReading>> streamAllSensors() {
    return sensorsRef.onValue.map((event) {
      final Map<String, SensorReading> sensors = {};
      
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        
        data.forEach((key, value) {
          try {
            if (value != null) {
              sensors[key.toString()] = SensorReading.fromJson(
                key.toString(),
                value as Map<dynamic, dynamic>,
              );
            }
          } catch (e) {
            // Use debugPrint for development only
            if (kDebugMode) {
              debugPrint('Error parsing sensor $key: $e');
            }
          }
        });
      }
      
      return sensors;
    });
  }

  /// Get single sensor data once
  Future<SensorReading?> getSensorOnce(String sensorId) async {
    try {
      final snapshot = await sensorsRef.child(sensorId).get();
      
      if (snapshot.exists && snapshot.value != null) {
        return SensorReading.fromJson(
          sensorId,
          snapshot.value as Map<dynamic, dynamic>,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting sensor $sensorId: $e');
      }
    }
    return null;
  }

  /// Stream single sensor data
  Stream<SensorReading?> streamSensor(String sensorId) {
    return sensorsRef.child(sensorId).onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        return SensorReading.fromJson(
          sensorId,
          event.snapshot.value as Map<dynamic, dynamic>,
        );
      }
      return null;
    });
  }

  /// Check Firebase connection status
  Stream<bool> streamConnectionStatus() {
    return FirebaseDatabase.instance
        .ref('.info/connected')
        .onValue
        .map((event) => event.snapshot.value as bool? ?? false);
  }

  // ============== ACTUATOR CONTROL ==============

  /// Set actuator state in Firebase (for hardware control)
  Future<void> setActuatorState(String actuatorId, bool isOn) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final firebaseId = _getFirebaseActuatorId(actuatorId);
      
      final updates = {
        'state': isOn,
        'timestamp': timestamp,
        'command': isOn ? 'ON' : 'OFF',
      };
      
      if (kDebugMode) {
        debugPrint('FirebaseService: Writing to /controls/$firebaseId');
        debugPrint('FirebaseService: Updates: $updates');
      }
      
      await actuatorsRef.child(firebaseId).update(updates);
      
      // Verify the write
      final snapshot = await actuatorsRef.child(firebaseId).child('state').get();
      if (kDebugMode) {
        debugPrint('FirebaseService: Write verified. State in Firebase: ${snapshot.value}');
        debugPrint('FirebaseService: Successfully set actuator $actuatorId ($firebaseId) to ${isOn ? "ON" : "OFF"}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FirebaseService: ERROR setting actuator state: $e');
        debugPrint('FirebaseService: Stack trace: ${StackTrace.current}');
      }
      rethrow;
    }
  }

  /// Get current actuator state
  Future<bool?> getActuatorState(String actuatorId) async {
    try {
      final firebaseId = _getFirebaseActuatorId(actuatorId);
      final snapshot = await actuatorsRef.child(firebaseId).child('state').get();
      if (snapshot.exists && snapshot.value != null) {
        return snapshot.value as bool;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FirebaseService: Error getting actuator state: $e');
      }
      return null;
    }
  }

  /// Stream actuator state changes (for real-time updates)
  Stream<bool?> streamActuatorState(String actuatorId) {
    final firebaseId = _getFirebaseActuatorId(actuatorId);
    return actuatorsRef.child(firebaseId).child('state').onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        return event.snapshot.value as bool;
      }
      return null;
    });
  }

  /// Get all actuator states
  Future<Map<String, bool>> getAllActuatorStates() async {
    try {
      final snapshot = await actuatorsRef.get();
      final Map<String, bool> states = {};
      
      // Mapping from Firebase IDs to app IDs
      final idMap = {
        'water_pump': 'pump',
        'led_lights': 'lights',
        'cooling_fan': 'fan',
      };
      
      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          if (value is Map && value['state'] != null) {
            final firebaseId = key.toString();
            final appId = idMap[firebaseId] ?? firebaseId;
            states[appId] = value['state'] as bool;
          }
        });
      }
      
      return states;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FirebaseService: Error getting all actuator states: $e');
      }
      return {};
    }
  }
}
