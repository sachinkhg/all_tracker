import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central app theme definitions: named color presets and font presets.
///
/// This file exposes simple APIs to build ThemeData instances from a seed
/// color and optional font family and to query available presets by key.
class AppTheme {
  /// Named color presets users can pick from in Settings.
  static const Map<String, Color> colorPresets = {
    'Blue': Colors.blue,
    'Green': Colors.green,
    'Purple': Colors.purple,
    'Amber': Colors.amber,
    'Teal': Colors.teal,
    'Indigo': Colors.indigo,
  };

  /// Named font presets using Google Fonts. `null` means use the system/default font.
  static const Map<String, String?> fontPresets = {
    'System': null,
    'Lato': 'Lato',
    'Roboto': 'Roboto',
    'Poppins': 'Poppins',
    'Open Sans': 'Open Sans',
    'Montserrat': 'Montserrat',
    'Geo': 'Geo',
  };

  /// Builds a ThemeData from a seed color, brightness and optional font.
  static ThemeData buildTheme({
    required Color seed,
    required Brightness brightness,
    String? fontFamily,
  }) {
    final cs = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);

    ThemeData base = ThemeData.from(colorScheme: cs, useMaterial3: true);
    if (fontFamily != null && fontFamily.isNotEmpty) {
      // Apply Google Fonts text theme based on the selected font
      TextTheme googleTextTheme;
      TextTheme googlePrimaryTextTheme;
      
      switch (fontFamily) {
        case 'Lato':
          googleTextTheme = GoogleFonts.latoTextTheme(base.textTheme);
          googlePrimaryTextTheme = GoogleFonts.latoTextTheme(base.primaryTextTheme);
          break;
        case 'Roboto':
          googleTextTheme = GoogleFonts.robotoTextTheme(base.textTheme);
          googlePrimaryTextTheme = GoogleFonts.robotoTextTheme(base.primaryTextTheme);
          break;
        case 'Inter':
          googleTextTheme = GoogleFonts.interTextTheme(base.textTheme);
          googlePrimaryTextTheme = GoogleFonts.interTextTheme(base.primaryTextTheme);
          break;
        case 'Poppins':
          googleTextTheme = GoogleFonts.poppinsTextTheme(base.textTheme);
          googlePrimaryTextTheme = GoogleFonts.poppinsTextTheme(base.primaryTextTheme);
          break;
        case 'Open Sans':
          googleTextTheme = GoogleFonts.openSansTextTheme(base.textTheme);
          googlePrimaryTextTheme = GoogleFonts.openSansTextTheme(base.primaryTextTheme);
          break;
        case 'Montserrat':
          googleTextTheme = GoogleFonts.montserratTextTheme(base.textTheme);
          googlePrimaryTextTheme = GoogleFonts.montserratTextTheme(base.primaryTextTheme);
          break;
        case 'Press Start 2P':
          googleTextTheme = GoogleFonts.pressStart2pTextTheme(base.textTheme);
          googlePrimaryTextTheme = GoogleFonts.pressStart2pTextTheme(base.primaryTextTheme);
          break;
        default:
          // Fallback to applying font family directly
          googleTextTheme = base.textTheme.apply(fontFamily: fontFamily);
          googlePrimaryTextTheme = base.primaryTextTheme.apply(fontFamily: fontFamily);
      }
      
      base = base.copyWith(
        textTheme: googleTextTheme,
        primaryTextTheme: googlePrimaryTextTheme,
      );
    }

    return base.copyWith(
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 2,
      ),
      iconTheme: IconThemeData(color: cs.onSurface),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}