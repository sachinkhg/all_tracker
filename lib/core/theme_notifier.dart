import 'package:flutter/material.dart';

/// ThemeNotifier provides a switchable light/dark ThemeData built from a seed color.
/// Use it with Provider/ChangeNotifierProvider and read `themeProvider.currentTheme`.
class ThemeNotifier extends ChangeNotifier {
  bool _isDark = false;

  /// Exposed ThemeData based on current mode.
  ThemeData get currentTheme => _isDark ? _darkTheme : _lightTheme;

  /// Toggle between light and dark and notify listeners.
  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }

  // Create a ThemeData from a seed color so we get a full ColorScheme.
  ThemeData _themeFromSeed(Color seedColor, {Brightness brightness = Brightness.light}) {
    final cs = ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness);

    return ThemeData.from(colorScheme: cs, useMaterial3: true).copyWith(
      // Make ElevatedButtons use the color scheme by default
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
        ),
      ),
      // AppBar uses primary / onPrimary
      appBarTheme: AppBarTheme(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 2,
      ),
      // Icon theme (fallback for icons that don't set color explicitly)
      iconTheme: IconThemeData(
        color: cs.onSurface,
      ),
      // You can add more theme customizations here (textTheme, inputDecorationTheme, etc.)
    );
  }

  // Change the seed color here if you want a different base color (green, indigo, etc.)
  ThemeData get _lightTheme => _themeFromSeed(Colors.blue, brightness: Brightness.light);
  ThemeData get _darkTheme => _themeFromSeed(Colors.green, brightness: Brightness.dark);
}
