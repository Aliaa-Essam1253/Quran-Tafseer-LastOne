import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  int _fontLevel = 1; // 0=Small 1=Medium 2=Large

  ThemeProvider() {
    _loadSettings();
  }

  ThemeMode get themeMode => _themeMode;
  int get currentFontLevel => _fontLevel;

  double get fontSize {
    switch (_fontLevel) {
      case 0:
        return 14.0;
      case 2:
        return 28.0;
      default:
        return 20.0;
    }
  }

  void toggleDarkMode(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _saveSettings();
    notifyListeners();
  }

  void setFontLevel(int level) {
    _fontLevel = level.clamp(0, 2);
    _saveSettings();
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _fontLevel = prefs.getInt('fontLevel') ?? 1;
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
    await prefs.setInt('fontLevel', _fontLevel);
  }
}
