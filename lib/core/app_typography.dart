import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  // Define your font families here
  static final String primaryFontFamily = GoogleFonts.lato().fontFamily!;
  static final String secondaryFontFamily = GoogleFonts.openSans().fontFamily!;

  // Optionally define TextStyle presets for common use cases
  static final TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(fontFamily: primaryFontFamily, fontSize: 96, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(fontFamily: primaryFontFamily, fontSize: 60, fontWeight: FontWeight.bold),
    displaySmall: TextStyle(fontFamily: primaryFontFamily, fontSize: 48),
    headlineMedium: TextStyle(fontFamily: primaryFontFamily, fontSize: 34),
    headlineSmall: TextStyle(fontFamily: primaryFontFamily, fontSize: 24),
    titleLarge: TextStyle(fontFamily: primaryFontFamily, fontSize: 20, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(fontFamily: secondaryFontFamily, fontSize: 16),
    bodyMedium: TextStyle(fontFamily: secondaryFontFamily, fontSize: 14),
    labelLarge: TextStyle(fontFamily: primaryFontFamily, fontSize: 14, fontWeight: FontWeight.bold),
    bodySmall: TextStyle(fontFamily: secondaryFontFamily, fontSize: 12),
    labelSmall: TextStyle(fontFamily: secondaryFontFamily, fontSize: 10),
  );
}
