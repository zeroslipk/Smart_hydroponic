import 'package:flutter/material.dart';
import '../models/sensor_reading.dart';
import '../providers/sensor_provider.dart';

class SensorMonitoringViewModel extends ChangeNotifier {
  final SensorProvider _sensorProvider;
  
  // Calibration offsets stored locally
  final Map<String, double> _calibrationOffsets = {};
  
  SensorMonitoringViewModel(this._sensorProvider);
  
  // Getters
  List<SensorReading> get sensors => _sensorProvider.getAllSensors();
  bool get isConnected => _sensorProvider.isConnected;
  
  double getCalibrationOffset(String sensorId) {
    return _calibrationOffsets[sensorId] ?? 0.0;
  }
  
  double getCalibratedValue(SensorReading sensor) {
    return sensor.value + getCalibrationOffset(sensor.id);
  }
  
  // Calibration
  void setCalibrationOffset(String sensorId, double offset) {
    _calibrationOffsets[sensorId] = offset;
    notifyListeners();
  }
  
  void resetCalibration(String sensorId) {
    _calibrationOffsets.remove(sensorId);
    notifyListeners();
  }
  
  // Sensor stats (mock data - in real app would come from SQLite history)
  Map<String, double> getSensorStats(SensorReading sensor) {
    return {
      'min': sensor.min,
      'max': sensor.max,
      'avg': (sensor.min + sensor.max) / 2,
    };
  }
}
