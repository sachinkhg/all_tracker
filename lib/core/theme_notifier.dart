import 'package:flutter/material.dart';
import 'app_theme.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeData _currentTheme = AppTheme.lightTheme;

  ThemeData get currentTheme => _currentTheme;

  void setTheme(String key) {
    _currentTheme = AppTheme.themes[key] ?? AppTheme.lightTheme;
    notifyListeners();
  }
}
