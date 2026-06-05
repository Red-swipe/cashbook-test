import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  Future<void> loadTheme() async {
    final value = await DatabaseHelper.instance.getSetting('theme');
    _themeMode = (value == 'light') ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    try {
      await DatabaseHelper.instance.setSetting(
        'theme', isDark ? 'dark' : 'light');
    } catch (e) {
      debugPrint('toggleTheme error: $e');
    }
  }
}
