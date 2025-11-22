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
}
