import 'package:all_tracker/goal_tracker/data/models/goal_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Hive initializer for the app.
///
/// Responsibility:
/// - Registers all Hive TypeAdapters used by the app (so Hive can serialize/deserialize objects).
/// - Opens the necessary Hive boxes for feature modules (returns the opened box here for immediate use).
/// - Ensures schema compatibility by making adapter registrations deterministic.
///
/// Boot order:
/// - MUST be called early in app startup (before DI finalization and before `runApp`).
///   Typical place: `main()` — perform `await HiveInitializer.initialize()` before constructing the DI graph
///   so repositories/data-sources find opened boxes.
///
/// Migration guidance:
/// - When adding a new Hive model:
///   1. Create the model and its generated adapter (or manual adapter).
///   2. Assign a unique `typeId` in the adapter. Record the new typeId and a short description in `migration_notes.md`.
///   3. Register the adapter here (and add an inline comment noting the mapping: `typeId -> Model`).
/// - If changing an existing model's fields:
///   * Prefer additive changes (new nullable fields). For breaking changes, add explicit migration code and document it in `migration_notes.md`.
///   * NEVER reuse a `typeId` for a different model — that causes hard-to-detect corruption.
/// - Keep a single source of truth for assigned typeIds (a central file or `migration_notes.md`) to avoid collisions.
///
/// Error handling strategy (recommended):
/// - Opening a corrupted box will throw. Recommended approaches:
///   1. Attempt recovery: catch the exception at the call site, backup the corrupted file, then try `Hive.deleteBoxFromDisk(boxName)` and re-open an empty box.
///   2. Surface a clear error to the user and provide an export/backup option if possible before deleting data.
/// - This initializer does *not* attempt recovery automatically; perform recovery where you call `initialize()` so the app can decide (e.g., show UI, log to crash reporting).
///
/// Developer note:
/// - This file contains only wiring and adapter registration. Keep migrations and data migrations separate (e.g., a `migrations/` folder or in `migration_notes.md`).
class HiveInitializer {

  /// Initializes Hive for the app and returns the opened goals box.
  ///
  /// - Registers the `GoalModel` adapter if not already registered.
  /// - Opens (and returns) the box named `'goals_box'`.
  /// - Caller responsibility:
  ///   * Ensure this is awaited during startup before DI setup that depends on Hive boxes.
  ///   * Handle errors thrown by `Hive.openBox` according to the app's recovery strategy (see header).
  static Future<Box<GoalModel>> initialize() async {
    // Initialize Hive Flutter bindings. This must be called before any Hive operations.
    await Hive.initFlutter();

    // -------------------------------------------------------------------------
    // Adapter registration
    // -------------------------------------------------------------------------
    // Obtain the adapter typeId from the generated adapter for clarity and to avoid magic numbers.
    // Mapping note: GoalModelAdapter().typeId -> GoalModel
    final adapterId = GoalModelAdapter().typeId;

    // Register adapter only if not already registered. This makes the initializer idempotent
    // which helps in tests and hot-reload scenarios where adapters may already be registered.
    if (!Hive.isAdapterRegistered(adapterId)) {
      // Registering a TypeAdapter is required for Hive to (de)serialize GoalModel instances.
      // Keep adapter registration order stable: register adapters before opening boxes that use them.
      Hive.registerAdapter(GoalModelAdapter());
    }

    // -------------------------------------------------------------------------
    // Box opening
    // -------------------------------------------------------------------------
    // Naming convention: use descriptive, lower_snake_case names with a feature prefix if needed.
    // Box: 'goals_box' — holds GoalModel entries for the goal_tracker feature.
    //
    // IMPORTANT: opening a box can throw if the file is corrupted or if there are incompatible adapters.
    // Recommendation: catch and handle exceptions at the call site (see file header).
    var box = await Hive.openBox<GoalModel>('goals_box');

    // Return the opened box so callers can use it immediately (e.g., to construct local data sources).
    return box;
  }
}
