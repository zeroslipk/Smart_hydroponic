import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:aquagrow_app/viewmodels/control_panel_viewmodel.dart';
import 'package:aquagrow_app/models/sensor_reading.dart';

void main() {
  group('ActuatorData Tests', () {
    test('ActuatorData should initialize correctly', () {
      final actuator = ActuatorData(
        id: 'test_pump',
        name: 'Test Pump',
        icon: Icons.water_drop,
        isActive: false,
        color: Colors.blue,
        runtime: '0h 0m',
      );

      expect(actuator.id, 'test_pump');
      expect(actuator.name, 'Test Pump');
      expect(actuator.isActive, false);
    });

    test('ActuatorData state toggle', () {
      final actuator = ActuatorData(
        id: 'test_pump',
        name: 'Test Pump',
        icon: Icons.water_drop,
        isActive: false,
        color: Colors.blue,
        runtime: '0h 0m',
      );

      actuator.isActive = true;
      expect(actuator.isActive, true);
    });
  });

  group('SensorReading Tests', () {
    test('SensorReading.fromJson parses valid data correctly', () {
      final json = {'value': 25.5, 'unit': '°C', 'timestamp': 1234567890};
      final sensor = SensorReading.fromJson('temp', json);

      expect(sensor.id, 'temp');
      expect(sensor.value, 25.5);
      expect(sensor.unit, '°C');
    });

    test('SensorReading handles different value types', () {
      final jsonInt = {'value': 25, 'unit': '°C', 'timestamp': 1234567890};
      final sensor = SensorReading.fromJson('temp', jsonInt);
      expect(sensor.value, 25.0); // Should convert int to double
    });
  });
}
