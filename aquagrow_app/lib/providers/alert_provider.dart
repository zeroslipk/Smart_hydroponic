import 'package:flutter/material.dart';
import 'dart:async';
import '../models/alert_model.dart';
import '../models/sensor_reading.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

/// Threshold configuration for each sensor
class SensorThreshold {
  final double criticalMin;
  final double criticalMax;
  final double warningMin;
  final double warningMax;

  const SensorThreshold({
    required this.criticalMin,
    required this.criticalMax,
    required this.warningMin,
    required this.warningMax,
  });
}

class AlertProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final NotificationService _notificationService = NotificationService();

  List<AlertModel> _alerts = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  // Default thresholds (can be customized in settings)
  final Map<String, SensorThreshold> _thresholds = {
    'temperature': const SensorThreshold(
      criticalMin: 15.0,
      criticalMax: 32.0,
      warningMin: 18.0,
      warningMax: 30.0,
    ),
    'pH': const SensorThreshold(
      criticalMin: 5.0,
      criticalMax: 7.5,
      warningMin: 5.5,
      warningMax: 7.0,
    ),
    'waterLevel': const SensorThreshold(
      criticalMin: 10.0,
      criticalMax: 100.0,
      warningMin: 20.0,
      warningMax: 100.0,
    ),
    'tds': const SensorThreshold(
      criticalMin: 0.0,
      criticalMax: 2500.0,
      warningMin: 0.0,
      warningMax: 2000.0,
    ),
    'light': const SensorThreshold(
      criticalMin: 0.0,
      criticalMax: 100000.0,  // Light can range from 0 to 100,000+ lux (indoor to direct sunlight)
      warningMin: 100.0,       // Below 100 lux is dim (indoor)
      warningMax: 50000.0,     // Above 50,000 lux is very bright (direct sunlight)
    ),
  };

  // Track last alert time per sensor to avoid spam
  final Map<String, DateTime> _lastAlertTime = {};
  // Track if sensor was in alert state (to reset cooldown when back to normal)
  final Map<String, bool> _wasInAlert = {};
  // Cooldown reduced to 15 seconds for faster notification response while preventing spam
  static const Duration _alertCooldown = Duration(seconds: 15);

  // Getters
  List<AlertModel> get alerts => _alerts;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  Map<String, SensorThreshold> get thresholds => _thresholds;

  AlertProvider() {
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _alerts = await _db.getAlerts(limit: 50);
      _unreadCount = await _db.getUnacknowledgedAlertCount();
    } catch (e) {
      debugPrint('Error loading alerts: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Check sensor reading against thresholds and create alert if needed
  Future<void> checkSensorReading(SensorReading sensor) async {
    final threshold = _thresholds[sensor.id];
    if (threshold == null) {
      debugPrint('AlertProvider: No threshold for ${sensor.id}');
      return;
    }

    debugPrint('AlertProvider: Checking ${sensor.id} = ${sensor.value} '
        '(critical: ${threshold.criticalMin}-${threshold.criticalMax})');

    // Check cooldown
    final lastAlert = _lastAlertTime[sensor.id];
    if (lastAlert != null &&
        DateTime.now().difference(lastAlert) < _alertCooldown) {
      debugPrint('AlertProvider: ${sensor.id} in cooldown');
      return;
    }

    AlertSeverity? severity;
    String? title;
    String? message;

    // Check critical thresholds first
    if (sensor.value < threshold.criticalMin) {
      severity = AlertSeverity.critical;
      title = '${sensor.displayName} Critical Low';
      message =
          '${sensor.displayName} dropped to ${sensor.displayValue}${sensor.unit}. '
          'Minimum safe level is ${threshold.criticalMin}${sensor.unit}.';
    } else if (sensor.value > threshold.criticalMax) {
      severity = AlertSeverity.critical;
      title = '${sensor.displayName} Critical High';
      message =
          '${sensor.displayName} reached ${sensor.displayValue}${sensor.unit}. '
          'Maximum safe level is ${threshold.criticalMax}${sensor.unit}.';
    }
    // Check warning thresholds
    else if (sensor.value < threshold.warningMin) {
      severity = AlertSeverity.warning;
      title = '${sensor.displayName} Low';
      message =
          '${sensor.displayName} is at ${sensor.displayValue}${sensor.unit}. '
          'Consider taking action soon.';
    } else if (sensor.value > threshold.warningMax) {
      severity = AlertSeverity.warning;
      title = '${sensor.displayName} High';
      message =
          '${sensor.displayName} is at ${sensor.displayValue}${sensor.unit}. '
          'Consider taking action soon.';
    }

    // Create alert if threshold exceeded
    if (severity != null && title != null && message != null) {
      debugPrint('AlertProvider: Creating $severity alert for ${sensor.id}');
      
      final alert = AlertModel(
        title: title,
        message: message,
        sensorId: sensor.id,
        sensorValue: sensor.value,
        unit: sensor.unit,
        severity: severity,
        timestamp: DateTime.now(),
      );

      await _db.insertAlert(alert);
      _lastAlertTime[sensor.id] = DateTime.now();
      _wasInAlert[sensor.id] = true;
      await _loadAlerts();
      
      // Show notification for critical and warning alerts
      if (severity == AlertSeverity.critical || severity == AlertSeverity.warning) {
        await _notificationService.showAlertNotification(alert);
      }
      
      debugPrint('AlertProvider: Alert created! Total alerts: ${_alerts.length}');
    } else {
      // Sensor is back to normal - reset cooldown so next alert triggers immediately
      if (_wasInAlert[sensor.id] == true) {
        debugPrint('AlertProvider: ${sensor.id} back to normal, resetting cooldown');
        _lastAlertTime.remove(sensor.id);
        _wasInAlert[sensor.id] = false;
      } else {
        debugPrint('AlertProvider: ${sensor.id} is within normal range');
      }
    }
  }

  /// Check all sensors at once
  Future<void> checkAllSensors(List<SensorReading> sensors) async {
    for (final sensor in sensors) {
      await checkSensorReading(sensor);
    }
  }

  /// Update threshold for a sensor
  void updateThreshold(String sensorId, SensorThreshold threshold) {
    _thresholds[sensorId] = threshold;
    notifyListeners();
  }

  /// Acknowledge single alert
  Future<void> acknowledgeAlert(int id) async {
    await _db.acknowledgeAlert(id);
    await _loadAlerts();
  }

  /// Acknowledge all alerts
  Future<void> acknowledgeAll() async {
    await _db.acknowledgeAllAlerts();
    await _loadAlerts();
  }

  /// Delete alert
  Future<void> deleteAlert(int id) async {
    await _db.deleteAlert(id);
    await _loadAlerts();
  }

  /// Refresh alerts
  Future<void> refresh() async {
    await _loadAlerts();
  }

  /// Get alerts by filter
  Future<List<AlertModel>> getFilteredAlerts({
    AlertSeverity? severity,
    bool? acknowledged,
  }) async {
    return await _db.getAlerts(
      limit: 100,
      severity: severity,
      acknowledged: acknowledged,
    );
  }

  /// Clean old alerts (e.g., older than 30 days)
  Future<void> cleanOldAlerts({int daysOld = 30}) async {
    await _db.deleteOldAlerts(daysOld);
    await _loadAlerts();
  }
}
