import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'theme_preferences_service.dart';

/// App-wide theme provider and helpers.
///
/// File responsibility:
/// - Exposes a single place to derive ThemeData variants (light/dark) from a seed color.
/// - Centralizes token composition (ColorScheme via seed, component defaults) so modules can
///   merge or extend themes consistently using `copyWith` or `ThemeData.merge`.
/// - Keeps theme construction deterministic and easy to override for feature variants.
///
/// Rationale for composition:
/// - We derive a full `ColorScheme` from a seed color and then create a `ThemeData` from it.
///   This ensures color harmony across components and makes it safe for modules to merge
///   their module-specific styles on top of a known base.
/// - Typography is intentionally left to higher-level composition; modules should call
///   `baseTheme.copyWith(textTheme: ...)` or `baseTheme.textTheme.merge(...)` so the font
///   metrics remain consistent app-wide while allowing per-module customization.
///
/// Adding new theme variants:
/// - To add a new variant (e.g., seeded/custom/dark-high-contrast):
///   1. Add a new getter returning `ThemeData` built via `_themeFromSeed` or a specialized builder.
///   2. Expose the variant through ThemeNotifier (or a ThemeRepository) and the UI switcher.
///   3. Persist user choice if required (e.g., in shared preferences) and restore during app startup.
///
/// Accessibility & best-practices:
/// - ColorScheme-derived colors (`onPrimary`, `onSurface`, etc.) are used to improve contrast automatically
///   between foreground and background in different brightness modes. Always favor semantic colors (from ColorScheme)
///   instead of hard-coded colors to keep accessibility consistent across variants.
/// - Test themes with different `MediaQuery.textScaleFactor` values to ensure layouts hold for large fonts.
/// - Provide a high-contrast variant if your user base requires it; build it from a seed but validate contrast ratios.
///
/// Why ThemeNotifier is global:
/// - Theme selection is global application state (a single source of truth). Making `ThemeNotifier` global via
///   Provider/ChangeNotifierProvider ensures all widgets observe the same theme and re-render when it changes.
/// - Persist user preference at a higher level (not shown in this file) so toggles survive app restarts.
///
/// Usage:
/// - Wrap the app with `ChangeNotifierProvider(create: (_) => ThemeNotifier())` and read `context.watch<ThemeNotifier>().currentTheme`
///   in `MaterialApp.theme`.
///
/// Keep this file focused on theme construction; persistence and user-settings live in a separate preferences layer.
class ThemeNotifier extends ChangeNotifier {
  final ThemePreferencesService _prefs = ThemePreferencesService();

  bool _isDark = false;
  String _themeKey = 'Blue';
  String _fontKey = 'System';

  Future<void> init() async {
    await _prefs.init();
    _themeKey = _prefs.loadThemeKey() ?? _themeKey;
    _fontKey = _prefs.loadFontKey() ?? _fontKey;
    _isDark = _prefs.loadIsDark();
    notifyListeners();
  }

  ThemeData get currentTheme {
    final seed = AppTheme.colorPresets[_themeKey] ?? Colors.blue;
    final font = AppTheme.fontPresets[_fontKey];
    final brightness = _isDark ? Brightness.dark : Brightness.light;
    return AppTheme.buildTheme(seed: seed, brightness: brightness, fontFamily: font);
  }

  String get themeKey => _themeKey;
  String get fontKey => _fontKey;
  bool get isDark => _isDark;

  Future<void> setTheme(String key) async {
    if (!AppTheme.colorPresets.containsKey(key)) return;
    _themeKey = key;
    await _prefs.saveThemeKey(key);
    notifyListeners();
  }

  Future<void> setFont(String key) async {
    if (!AppTheme.fontPresets.containsKey(key)) return;
    _fontKey = key;
    await _prefs.saveFontKey(key);
    notifyListeners();
  }

  Future<void> toggleDark(bool value) async {
    _isDark = value;
    await _prefs.saveIsDark(value);
    notifyListeners();
  }

  /// Build a ThemeData from a seed color so we get a full ColorScheme.
  ///
  /// - `ColorScheme.fromSeed` produces a consistent color palette for both light and dark modes.
  /// - We then create a base ThemeData via `ThemeData.from(colorScheme: cs, useMaterial3: true)`
  ///   and selectively `copyWith` component-level overrides. Using `copyWith` is intentional:
  ///   it merges our small set of component customizations onto a stable base provided by Material.
  ///
  /// Non-trivial merges:
  /// - The `copyWith` call below is where we provide component defaults that should align with the ColorScheme.
  ///   Module-level themes should merge with this ThemeData rather than replace it to avoid token drift.
  // ThemeData _themeFromSeed(Color seedColor, {Brightness brightness = Brightness.light}) {
  //   // Derive a ColorScheme so component defaults follow the seed's palette.
  //   final cs = ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness);

  //   return ThemeData.from(colorScheme: cs, useMaterial3: true).copyWith(
  //     // Make ElevatedButtons use the color scheme by default.
  //     // Using `styleFrom` ties button backgrounds/foregrounds to the ColorScheme ensuring contrast.
  //     elevatedButtonTheme: ElevatedButtonThemeData(
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: cs.primary,
  //         foregroundColor: cs.onPrimary,
  //       ),
  //     ),
  //     // AppBar uses primary / onPrimary so it contrasts with scaffold background.
  //     // Elevation is a small UX choice; keep it modest for a lightweight material feel.
  //     appBarTheme: AppBarTheme(
  //       backgroundColor: cs.primary,
  //       foregroundColor: cs.onPrimary,
  //       elevation: 2,
  //     ),
  //     // Icon theme: a sensible fallback for icons that don't set color explicitly.
  //     // Uses onSurface to ensure icons remain visible across light/dark backgrounds.
  //     iconTheme: IconThemeData(
  //       color: cs.onSurface,
  //     ),
  //     // You can add more theme customizations here (textTheme, inputDecorationTheme, etc.)
  //     // Prefer adding semantic tokens (e.g., highContrast theme) rather than hard-coded overrides.
  //   );
  // }

  // Legacy getters retained for compatibility; not used when presets are active.
  // ThemeData get _lightTheme => _themeFromSeed(Colors.blue, brightness: Brightness.light);
  // ThemeData get _darkTheme => _themeFromSeed(Colors.green, brightness: Brightness.dark);
}
