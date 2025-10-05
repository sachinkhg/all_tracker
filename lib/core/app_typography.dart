import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  // Define your font families here
  static final String primaryFontFamily = GoogleFonts.lato().fontFamily!;
  // static final String secondaryFontFamily = GoogleFonts.openSans().fontFamily!;

  /// Build a text theme with dynamic colors from [colorScheme].
  static TextTheme textTheme(ColorScheme colorScheme) {
    return TextTheme(
      headlineSmall: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 24,
        color: colorScheme.primary,
      ),
      titleLarge: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: colorScheme.primary, // titles use primary
      ),
      bodyLarge: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: colorScheme.primary,
      ),
      bodyMedium: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 14,
        fontStyle: FontStyle.italic,
        color: colorScheme.primary,
      ),
      labelLarge: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: colorScheme.secondary,
      ),
      bodySmall: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 14,
        color: colorScheme.primary.withOpacity(0.8),
      ),
    );
  }
}
