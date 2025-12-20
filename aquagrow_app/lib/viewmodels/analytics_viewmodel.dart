import 'package:flutter/material.dart';
import '../models/sensor_reading.dart';
import '../providers/sensor_provider.dart';

class AnalyticsViewModel extends ChangeNotifier {
  final SensorProvider _sensorProvider;
  
  String _selectedPeriod = '24h';
  String _selectedSensor = 'All';
  
  final List<String> periods = ['24h', '7d', '30d', '90d'];
  final List<String> sensorOptions = ['All', 'Temperature', 'pH', 'Water Level', 'TDS', 'Light'];
  
  AnalyticsViewModel(this._sensorProvider);
  
  // Getters
  String get selectedPeriod => _selectedPeriod;
  String get selectedSensor => _selectedSensor;
  List<SensorReading> get sensors => _sensorProvider.getAllSensors();
  
  // Setters
  void setPeriod(String period) {
    _selectedPeriod = period;
    notifyListeners();
  }
  
  void setSensor(String sensor) {
    _selectedSensor = sensor;
    notifyListeners();
  }
  
  // Export methods
  String generateCSV() {
    final buffer = StringBuffer();
    buffer.writeln('Sensor,Value,Unit,Status,Min,Max,Timestamp');
    
    for (final sensor in sensors) {
      buffer.writeln('${sensor.displayName},${sensor.value},${sensor.unit},${sensor.status},${sensor.min},${sensor.max},${DateTime.now().toIso8601String()}');
    }
    
    return buffer.toString();
  }
  
  Map<String, dynamic> generateReportData() {
    return {
      'sensorCount': sensors.length,
      'period': _selectedPeriod,
      'generatedAt': DateTime.now().toString().substring(0, 16),
      'sensors': sensors.map((s) => {
        'name': s.displayName,
        'value': s.value,
        'unit': s.unit,
        'status': s.status,
      }).toList(),
    };
  }
}
