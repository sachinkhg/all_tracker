import 'package:flutter/material.dart';

import 'app_typography.dart';
class AppTheme {
  static const Color primaryLight = Color(0xFFFDFFFC);
  static const Color primaryDark = Color(0xFF011627);
  static const Color primaryGreen = Color(0xFF2EC4B6);
  static const Color primaryRed = Color(0xFFE71D36);
  static const Color primaryYellow = Color(0xFFFF9F1C);
  

  static final ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primaryLight,
    onPrimary: primaryDark,  
    secondary: primaryLight,
    onSecondary: primaryDark, 
    error: primaryLight, 
    onError: primaryRed, 
    surface: primaryLight, 
    onSurface: primaryYellow,
  );

  static final ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primaryDark,
    onPrimary: primaryLight,  
    secondary: primaryDark,
    onSecondary: primaryLight, 
    error: primaryLight, 
    onError: primaryRed, 
    surface: primaryLight, 
    onSurface: primaryYellow,
  );

  static final ColorScheme greenColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primaryLight,
    onPrimary: primaryGreen,
    secondary: primaryLight,
    onSecondary: primaryGreen,
    error: primaryLight, 
    onError: primaryRed, 
    surface: primaryLight, 
    onSurface: primaryYellow,
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
