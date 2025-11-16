import 'package:flutter/material.dart';

/// Centralized design tokens for spacing, radii, elevations, gradients and animations.
///
/// Do not hardcode raw values in widgets. Pull from here so the design stays
/// consistent and can be tuned in one place.
class AppSpacing {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
}

class AppRadii {
  static const double card = 16;
  static const double chip = 12;
  static const double button = 14;
}

class AppElevations {
  static const double card = 4;
  static const double pressed = 6;
}

class AppGradients {
  /// Primary gradient derived from the theme's [ColorScheme].
  static LinearGradient primary(ColorScheme cs) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          cs.primary,
          cs.primaryContainer,
        ],
      );

  /// AppBar gradient with improved readability in both light and dark themes.
  /// Uses lighter shades in dark mode and softer shades in light mode.
  static LinearGradient appBar(ColorScheme cs) {
    final isDark = cs.brightness == Brightness.dark;
    
    // In dark mode: use lighter primary shades to avoid too-dark black
    // In light mode: use slightly muted/darker shades to avoid too-bright white
    if (isDark) {
      // Blend primary with surface for a lighter, more readable background
      final startColor = Color.lerp(
        cs.primary,
        cs.surface,
        0.15, // Make it 15% lighter by blending with surface
      ) ?? cs.primary;
      
      final endColor = Color.lerp(
        cs.primaryContainer,
        cs.surface,
        0.25, // Make it 25% lighter
      ) ?? cs.primaryContainer;
      
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [startColor, endColor],
      );
    } else {
      // In light mode: blend with a subtle darker tone to reduce brightness
      final startColor = Color.lerp(
        cs.primary,
        Colors.black,
        0.08, // Make it slightly darker (8% towards black)
      ) ?? cs.primary;
      
      final endColor = Color.lerp(
        cs.primaryContainer,
        Colors.black,
        0.05, // Make it slightly darker (5% towards black)
      ) ?? cs.primaryContainer;
      
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [startColor, endColor],
      );
    }
  }

  /// Secondary gradient derived from the theme's [ColorScheme].
  static LinearGradient secondary(ColorScheme cs) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          cs.secondary,
          cs.secondaryContainer,
        ],
      );

  /// Tertiary gradient derived from the theme's [ColorScheme].
  static LinearGradient tertiary(ColorScheme cs) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          cs.tertiary,
          cs.tertiaryContainer,
        ],
      );
}

class AppAnimations {
  static const Duration micro = Duration(milliseconds: 180);
  static const Duration short = Duration(milliseconds: 260);
  static const Duration medium = Duration(milliseconds: 360);

  static const Curve ease = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
}


