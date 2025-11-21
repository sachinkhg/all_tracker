import 'package:all_tracker/core/hive_initializer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/app_typography.dart';
import 'pages/app_home_page.dart';
import 'core/theme_notifier.dart';
import 'features/auth/core/injection.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/states/auth_state.dart';

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

  /// Step 3: Initialize and provide ThemeNotifier and AuthCubit.
  /// This allows the app to listen for and react to theme changes and auth state globally.
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier()..init(),
      child: BlocProvider(
        create: (_) => createAuthCubit()..checkAuthStatus(),
        child: const MyApp(),
      ),
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
    // Determine the selected font family from currentTheme.textTheme; if the
    // theme layer (AppTheme) set a custom font, pass it through.
    final String? selectedFontFamily = themeProvider.currentTheme.textTheme.bodyMedium?.fontFamily;

    final ThemeData mergedTheme = themeProvider.currentTheme.copyWith(
      textTheme: AppTypography.textTheme(
        themeProvider.currentTheme.colorScheme,
        fontFamily: selectedFontFamily,
      ),
      primaryTextTheme: AppTypography.textTheme(
        themeProvider.currentTheme.colorScheme,
        fontFamily: selectedFontFamily,
      ),
    );

    return MaterialApp(
      title: 'Goal Tracker',
      debugShowCheckedModeBanner: false,

      /// Active (light) theme
      theme: mergedTheme,

      /// Optional: Dark theme configuration
      /// You can define a separate dark theme in `ThemeNotifier` if desired.
      darkTheme: themeProvider.currentTheme.copyWith(
        textTheme: AppTypography.textTheme(
          themeProvider.currentTheme.colorScheme,
          fontFamily: selectedFontFamily,
        ),
        primaryTextTheme: AppTypography.textTheme(
          themeProvider.currentTheme.colorScheme,
          fontFamily: selectedFontFamily,
        ),
      ),

      /// Conditional routing based on authentication state
      /// - Show LoginPage if user is not authenticated
      /// - Show AppHomePage if user is authenticated
      home: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return const AppHomePage();
          } else if (state is AuthUnauthenticated || state is AuthInitial || state is AuthError) {
            return const LoginPage();
          } else {
            // Loading state - show loading screen or login page
            return const LoginPage();
          }
        },
      ),
    );
  }
}
