import 'package:flutter/material.dart';
// If you want to supply GoogleFonts, do it from the Theme layer and pass the
// resolved fontFamily into [AppTypography.textTheme]. Avoid hard-coding a
// specific font here so Settings can switch fonts dynamically.

/// App theme tokens and helpers — typography portion.
///
/// File responsibility:
/// - Central place for app typography tokens (font families, text styles) used by ThemeData.
/// - Provides a `textTheme(ColorScheme)` builder so module themes can merge consistent, color-aware
///   typography into their own ThemeData via `copyWith(textTheme: ...)`.
///
/// Rationale for composition:
/// - We keep typography separate from color/shape tokens so modules can compose a base theme
///   and override only the pieces they need. For example, a module can take `baseTheme.copyWith(...)`
///   and merge its module-specific text styles while retaining the global token set.
/// - Merging typography with a base theme ensures consistent metrics (font size, weight, family)
///   across the app while allowing color and semantic changes per theme variant (light/dark/seeded).
///
/// Adding new theme variants:
/// 1. Create a ThemeData variant (e.g., `appLightTheme`, `appDarkTheme`, `appSeededTheme`) in a central
///    theme file (e.g., `core/theme/app_theme.dart` or `core/theme/themes.dart`).
/// 2. Use `AppTypography.textTheme(colorScheme)` to supply consistent typography to each variant:
///    ```dart
///    final base = ThemeData.from(colorScheme: colorScheme);
///    return base.copyWith(textTheme: AppTypography.textTheme(colorScheme));
///    ```
/// 3. Expose the new variant from a single entry point (ThemeNotifier or ThemeRepository) so UI can switch variants.
///
/// Accessibility & guidance:
/// - Keep font sizes and weights accessible and test with system font scaling (MediaQuery.textScaleFactor).
/// - Prefer using colorScheme-based colors for text so the same typography adapts automatically across themes.
/// - When adding new text styles, consider whether they are semantic (e.g., headline, body) so accessibility tools map correctly.
///
/// Developer note:
/// - This file is intentionally focused on typography tokens. Do not register colors or shapes here — keep theme composition at a higher level.
/// - Module authors should extend or merge these styles rather than copy them to avoid drift.
class AppTypography {

  /// Build a [TextTheme] that picks colors from the provided [colorScheme].
  ///
  /// - This returns a *semantic* TextTheme where color references come from the ColorScheme so that
  ///   the same typography adapts to light/dark/seeded variants without changing font metrics.
  /// - Modules should merge this via `baseTheme.copyWith(textTheme: AppTypography.textTheme(baseTheme.colorScheme))`
  ///   or derive specific adjustments using `merge`.
  ///
  /// Accessibility notes:
  /// - Sizes chosen here are modest and subject to system text scaling; prefer testing with `textScaleFactor`.
  /// - Contrast decisions should be validated against WCAG; using `colorScheme.primary` for titles emphasizes brand color,
  ///   but ensure sufficient contrast against background in each theme variant.
  /// Optionally provide [fontFamily] to enforce a specific font across the
  /// returned [TextTheme]. When `null`, the theme’s current font will be used.
  static TextTheme textTheme(ColorScheme colorScheme, {String? fontFamily}) {
    return TextTheme(
      // Headline for small screens / secondary headings. Using primary color for brand emphasis.
      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 24,
        color: colorScheme.primary,
      ),
      // TitleLarge used for prominent in-screen titles.
      // .w500 gives moderate emphasis without being too heavy for accessibility.
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: colorScheme.primary, // titles use primary to keep consistent brand color
      ),
      // BodyLarge — primary readable body text. Keep weight slightly elevated for legibility.
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: colorScheme.primary,
      ),
      // BodyMedium — used for secondary body copy; italic signals emphasis but should be used sparingly.
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontStyle: FontStyle.italic,
        color: colorScheme.primary,
      ),
      // Labels (e.g., chips, small buttons) use the secondary color to provide contrast and semantic separation.
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: colorScheme.primary,
      ),
      // BodySmall for helper text or captions. Slight opacity reduces visual weight while keeping color linked to scheme.
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        color: colorScheme.primary.withOpacity(0.8),
      ),
    );
  }
}
