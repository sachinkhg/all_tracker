/// Central dependency injection container for the application.
///
/// This file provides a centralized DI container using get_it for managing
/// dependencies across all modules. It replaces manual factory functions with
/// a container-based approach.
///
/// Organization:
/// - Shared services (preferences, etc.) are registered here as singletons
/// - Module-specific dependencies are registered via module injection functions
/// - All dependencies are registered before app startup in main.dart
///
/// Usage:
/// - Call `configureDependencies()` in main.dart after Hive initialization
/// - Use `getIt.get<T>()` or `getIt<T>()` to resolve dependencies
/// - For factories (e.g., cubits), use `getIt.getFactory<T>()` or register as factories
///
/// Testing:
/// - Reset the container between tests: `getIt.reset()`
/// - Override dependencies in tests by registering mocks before resolving

import 'package:get_it/get_it.dart';
import 'package:all_tracker/core/services/box_provider.dart';
import 'package:all_tracker/core/services/view_preferences_service.dart';
import 'package:all_tracker/core/services/filter_preferences_service.dart';
import 'package:all_tracker/core/services/sort_preferences_service.dart';

/// Global instance of the dependency injection container.
final GetIt getIt = GetIt.instance;

/// Configures all app-wide dependencies.
///
/// This function registers shared services that are used across multiple modules.
/// Module-specific dependencies should be registered via their respective
/// injection files (e.g., goal_tracker/core/injection.dart).
///
/// Must be called after Hive initialization in main.dart.
void configureDependencies() {
  // Reset container to avoid duplicate registrations during hot reload
  if (getIt.isRegistered<ViewPreferencesService>()) {
    getIt.reset();
  }

  // Register BoxProvider as a singleton
  getIt.registerSingleton<BoxProvider>(HiveBoxProvider());

  // Register preference services as singletons
  getIt.registerSingleton<ViewPreferencesService>(
    ViewPreferencesService(boxes: getIt<BoxProvider>()),
  );

  getIt.registerSingleton<FilterPreferencesService>(
    FilterPreferencesService(boxes: getIt<BoxProvider>()),
  );

  getIt.registerSingleton<SortPreferencesService>(
    SortPreferencesService(boxes: getIt<BoxProvider>()),
  );
}

/// Resets all registered dependencies.
///
/// Useful for testing or hot reload scenarios.
void resetDependencies() {
  getIt.reset();
}

