import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  final String key = "themeMode";
  SharedPreferences? _prefs;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadFromPrefs().catchError((e) {
      debugPrint("Error loading theme: $e");
    });
  }

  ThemeData get themeData {
    return _isDarkMode ? _darkTheme : _lightTheme;
  }

  void toggleTheme(bool isOn) {
    _isDarkMode = isOn;
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _loadFromPrefs() async {
    await _initPrefs();
    _isDarkMode = _prefs?.getBool(key) ?? false;
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    await _initPrefs();
    _prefs?.setBool(key, _isDarkMode);
  }

  static final ThemeData _lightTheme = ThemeData(
    primaryColor: const Color(0xFF006064),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00BCD4),
      primary: const Color(0xFF006064),
      secondary: const Color(0xFF7CB342),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    cardColor: Colors.white,
    fontFamily: 'Roboto',
    useMaterial3: true,
    brightness: Brightness.light,
  );

  static final ThemeData _darkTheme = ThemeData(
    primaryColor: const Color(0xFF006064),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00BCD4),
      primary: const Color(0xFF80DEEA), // Lighter cyan for dark mode
      secondary: const Color(0xFFAED581), // Lighter green for dark mode
      surface: const Color(0xFF1E1E1E), // Dark surface
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),

    fontFamily: 'Roboto',
    useMaterial3: true,
    brightness: Brightness.dark,
  );
}
