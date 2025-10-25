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


