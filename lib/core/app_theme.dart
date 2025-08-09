import 'package:flutter/material.dart';

import 'app_typography.dart';
class AppTheme {
  static const Color primaryLight = Colors.white;
  static const Color primaryDark = Colors.black;
  static const Color primaryGreen = Colors.green;

  static final ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primaryLight,
    onPrimary: primaryDark,  
    secondary: primaryLight,
    onSecondary: primaryDark, 
    error: primaryLight, 
    onError: primaryDark, 
    surface: primaryLight, 
    onSurface: primaryDark,
  );

  static final ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primaryDark,
    onPrimary: primaryLight,  
    secondary: primaryDark,
    onSecondary: primaryLight, 
    error: primaryDark, 
    onError: primaryLight, 
    surface: primaryDark, 
    onSurface: primaryLight,
  );

  static final ColorScheme greenColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primaryGreen,
    onPrimary: primaryLight,
    secondary: primaryGreen,
    onSecondary: primaryLight,
    error: primaryGreen,
    onError: primaryLight,
    surface: primaryGreen,
    onSurface: primaryLight,
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: lightColorScheme,
    primaryColor: lightColorScheme.primary,
    scaffoldBackgroundColor: lightColorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: lightColorScheme.primary,
      foregroundColor: lightColorScheme.onPrimary,
    ),
    textTheme: AppTypography.textTheme,
    buttonTheme: ButtonThemeData(
      buttonColor: lightColorScheme.primary,
      textTheme: ButtonTextTheme.primary,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: darkColorScheme,
    primaryColor: darkColorScheme.primary,
    scaffoldBackgroundColor: darkColorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: darkColorScheme.primary,
      foregroundColor: darkColorScheme.onPrimary,
    ),
    textTheme: AppTypography.textTheme,
    buttonTheme: ButtonThemeData(
      buttonColor: darkColorScheme.primary,
      textTheme: ButtonTextTheme.primary,
    ),
  );

  static final ThemeData greenTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: greenColorScheme,
    primaryColor: greenColorScheme.primary,
    scaffoldBackgroundColor: greenColorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: greenColorScheme.primary,
      foregroundColor: greenColorScheme.onPrimary,
    ),
    textTheme: AppTypography.textTheme,
    buttonTheme: ButtonThemeData(
      buttonColor: greenColorScheme.primary,
      textTheme: ButtonTextTheme.primary,
    ),
  );

  static final themes = <String, ThemeData>{
    'Light': lightTheme,
    'Dark': darkTheme,
    'Green': greenTheme,
  };
}
