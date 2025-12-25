import 'package:all_tracker/core/hive_initializer.dart';
import 'package:all_tracker/core/injection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/app_typography.dart';
import 'pages/app_home_page.dart';
import 'core/theme_notifier.dart';
import 'core/organization_notifier.dart';
import 'trackers/goal_tracker/presentation/pages/goal_tracker_home_page.dart';
import 'trackers/travel_tracker/presentation/pages/travel_tracker_home_page.dart';
import 'utilities/investment_planner/presentation/pages/investment_planner_home_page.dart';
import 'utilities/retirement_planner/presentation/pages/retirement_planner_home_page.dart';
import 'features/auth/core/injection.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/states/auth_state.dart';
import 'features/backup/core/injection.dart';
import 'features/backup/core/backup_scheduler_service.dart';
import 'features/backup/core/backup_sync_service.dart';

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

  /// Step 2.5: Configure dependency injection container.
  /// This registers all shared services and prepares the DI container
  /// for module-specific dependency registration.
  configureDependencies();

  /// Step 3: Initialize and provide ThemeNotifier, OrganizationNotifier, and AuthCubit.
  /// This allows the app to listen for and react to theme changes, organization preferences, and auth state globally.
  final themeNotifier = ThemeNotifier();
  final organizationNotifier = OrganizationNotifier();
  
  // Initialize both notifiers
  await themeNotifier.init();
  await organizationNotifier.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeNotifier),
        ChangeNotifierProvider.value(value: organizationNotifier),
      ],
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
///   - App lifecycle observation for automatic backups
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // Temporarily disabled - will be re-enabled after fixing automatic backup issues
  // ignore: unused_field
  late final BackupSchedulerService _backupScheduler;
  // Temporarily disabled - will be re-enabled after fixing automatic backup issues
  // ignore: unused_field
  late final BackupSyncService _backupSyncService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _backupScheduler = createBackupSchedulerService();
    _backupSyncService = createBackupSyncService();
    
    // Check for restore on app startup (after a short delay to ensure everything is initialized)
    // PAUSED: Backup sync temporarily disabled - will fix and re-enable later
    // Future.delayed(const Duration(seconds: 2), () {
    //   if (mounted) {
    //     _backupSyncService.checkAndRestoreIfNeeded();
    //   }
    // });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      // Trigger automatic backup when app goes to background
      // PAUSED: Automatic backup temporarily disabled - will fix and re-enable later
      // _backupScheduler.runAutomaticBackup();
    } else if (state == AppLifecycleState.resumed) {
      // Check for restore when app comes to foreground
      // Wait a bit to ensure any backup created when going to background is indexed
      // PAUSED: Backup sync temporarily disabled - will fix and re-enable later
      // Future.delayed(const Duration(seconds: 3), () {
      //   if (mounted) {
      //     _backupSyncService.checkAndRestoreIfNeeded();
      //   }
      // });
    }
  }

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

      /// Conditional routing based on authentication state and default home page preference
      /// - Show LoginPage if user is not authenticated
      /// - Show default home page (from OrganizationNotifier) if user is authenticated
      home: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            final orgNotifier = Provider.of<OrganizationNotifier>(context, listen: false);
            final defaultHomePage = orgNotifier.defaultHomePage;
            
            // Navigate to the default home page based on preference
            switch (defaultHomePage) {
              case 'goal_tracker':
                return const HomePage();
              case 'travel_tracker':
                return const TravelTrackerHomePage();
              case 'investment_planner':
                return const InvestmentPlannerHomePage();
              case 'retirement_planner':
                return const RetirementPlannerHomePage();
              case 'app_home':
              default:
                return const AppHomePage();
            }
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
