import 'package:all_tracker/core/hive_initializer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_typography.dart';
import 'goal_tracker/presentation/pages/home_page.dart';
import 'core/theme_notifier.dart';

/// ============================================================================
/// APPLICATION ENTRY POINT
/// ----------------------------------------------------------------------------
/// File: main.dart
/// Purpose:
///   - Bootstraps the Flutter application.
///   - Initializes Hive (local database).
///   - Sets up dependency injection (DI) and global providers.
///   - Launches the root `MyApp` widget which defines theming and routing.
///
/// Lifecycle Overview:
///   1. Ensure Flutter engine bindings are initialized.
///   2. Initialize Hive boxes and adapters via [HiveInitializer].
///   3. Register any app-wide dependencies (DI) here if required.
///   4. Launch app with [ChangeNotifierProvider] for Theme management.
///   5. Render `MyApp` (root widget).
///
/// Route Configuration:
///   - The app currently starts at `HomePage()`
///   - To change the initial route:
///         → Update `home:` property in `MaterialApp`
///         → OR configure named routes and set `initialRoute`
///
/// Feature/Module Route Registration:
///   - Each feature module (e.g. goal_tracker, habit_tracker) should
///     provide its own route registrar (e.g., `GoalRoutes.register()`).
///   - These registrars can be called during app startup or
///     inside a central `RouteManager` file under `/core/routes/`.
///
/// ============================================================================

Future<void> main() async {
  /// Step 1: Ensure Flutter framework bindings are initialized.
  /// Required before using platform channels or asynchronous initializers.
  WidgetsFlutterBinding.ensureInitialized();

  /// Step 2: Initialize Hive database and register adapters/boxes.
  /// This ensures that local persistence (for Goals, Settings, etc.)
  /// is ready before the app runs.
  await HiveInitializer.initialize();

  /// Step 3: Initialize and provide ThemeNotifier.
  /// This allows the app to listen for and react to theme changes globally.
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const MyApp(),
    ),
  );
}

/// Root widget of the application.
/// Handles:
///   - Theming (light/dark + typography merge)
///   - Route entry point (`HomePage`)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    /// Retrieve the current theme from the global ThemeNotifier provider.
    final themeProvider = Provider.of<ThemeNotifier>(context);

    /// Merge typography definitions (from `core/app_typography.dart`)
    /// with the current ThemeData for consistent font styling across app.
    final ThemeData mergedTheme = themeProvider.currentTheme.copyWith(
      textTheme: AppTypography.textTheme(themeProvider.currentTheme.colorScheme),
      primaryTextTheme: AppTypography.textTheme(themeProvider.currentTheme.colorScheme),
    );

    return MaterialApp(
      title: 'Goal Tracker',
      debugShowCheckedModeBanner: false,

      /// Active (light) theme
      theme: mergedTheme,

      /// Optional: Dark theme configuration
      /// You can define a separate dark theme in `ThemeNotifier` if desired.
      darkTheme: themeProvider.currentTheme.copyWith(
        textTheme: AppTypography.textTheme(themeProvider.currentTheme.colorScheme),
        primaryTextTheme: AppTypography.textTheme(themeProvider.currentTheme.colorScheme),
      ),

      /// Current initial route → HomePage
      /// To modify:
      ///   - Replace with another widget
      ///   - Or use `initialRoute` and `routes` for multi-screen navigation
      home: const HomePage(),
    );
  }
}
