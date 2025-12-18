import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../providers/alert_provider.dart';
import '../services/voice_service.dart';

class AlertsViewModel extends ChangeNotifier {
  final AlertProvider _alertProvider;
  final VoiceService _voiceService = VoiceService();
  
  String _selectedFilter = 'All';
  final List<String> filters = ['All', 'Critical', 'Warning', 'Info'];
  
  AlertsViewModel(this._alertProvider) {
    _voiceService.initialize();
  }
  
  // Getters
  String get selectedFilter => _selectedFilter;
  List<AlertModel> get alerts => _alertProvider.alerts;
  int get unreadCount => _alertProvider.unreadCount;
  bool get isLoading => _alertProvider.isLoading;
  
  List<AlertModel> get filteredAlerts {
    if (_selectedFilter == 'All') return alerts;
    return alerts.where((a) => a.severityLabel == _selectedFilter).toList();
  }
  
  int get criticalCount => alerts.where((a) => a.severity == AlertSeverity.critical).length;
  int get warningCount => alerts.where((a) => a.severity == AlertSeverity.warning).length;
  int get infoCount => alerts.where((a) => a.severity == AlertSeverity.info).length;
  
  // Actions
  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }
  
  Future<void> acknowledgeAlert(int alertId) async {
    await _alertProvider.acknowledgeAlert(alertId);
    notifyListeners();
  }
  
  Future<void> deleteAlert(int alertId) async {
    await _alertProvider.deleteAlert(alertId);
    notifyListeners();
  }
  
  void speakAlert(AlertModel alert) {
    _voiceService.speakAlert(alert);
  }
}
