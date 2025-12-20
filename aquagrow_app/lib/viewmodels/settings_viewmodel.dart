import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class SettingsViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _db = DatabaseService();
  
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  String _temperatureUnit = 'Celsius';
  String _theme = 'System';
  
  // Getters
  bool get notificationsEnabled => _notificationsEnabled;
  bool get soundEnabled => _soundEnabled;
  String get temperatureUnit => _temperatureUnit;
  String get theme => _theme;
  String? get userEmail => _authService.currentUser?.email;
  String? get userName => _authService.currentUser?.displayName;
  
  // Setters
  void setNotificationsEnabled(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }
  
  void setSoundEnabled(bool value) {
    _soundEnabled = value;
    notifyListeners();
  }
  
  void setTemperatureUnit(String unit) {
    _temperatureUnit = unit;
    notifyListeners();
  }
  
  void setTheme(String theme) {
    _theme = theme;
    notifyListeners();
  }
  
  // Actions
  Future<void> signOut() async {
    await _authService.signOut();
  }
  
  Future<void> clearAllData() async {
    await _db.clearAllData();
    notifyListeners();
  }
}
