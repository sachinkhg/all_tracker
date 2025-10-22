import 'package:all_tracker/goal_tracker/data/models/goal_model.dart';
import 'package:all_tracker/goal_tracker/data/models/milestone_model.dart';
import 'package:all_tracker/goal_tracker/data/models/task_model.dart';
import 'package:all_tracker/goal_tracker/core/constants.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Hive initializer for the app.
///
/// Responsibility:
/// - Registers all Hive TypeAdapters used by the app (so Hive can serialize/deserialize objects).
/// - Opens the necessary Hive boxes for feature modules (returns them for immediate use).
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
  /// Initializes Hive for the app and returns goal, milestone, and task boxes.
  ///
  /// - Registers adapters if not already registered.
  /// - Opens boxes `'goals_box'`, `'milestones_box'`, and `'tasks_box'`.
  /// - Prints contents for verification.
  /// - Must be awaited before DI setup and `runApp`.
  static Future<HiveBoxes> initialize() async {
    // Initialize Hive Flutter bindings. This must be called before any Hive operations.
    await Hive.initFlutter();

    // -------------------------------------------------------------------------
    // Adapter registration
    // -------------------------------------------------------------------------
    final goalAdapterId = GoalModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(goalAdapterId)) {
      Hive.registerAdapter(GoalModelAdapter());
    }

    final milestoneAdapterId = MilestoneModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(milestoneAdapterId)) {
      Hive.registerAdapter(MilestoneModelAdapter());
    }

    final taskAdapterId = TaskModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(taskAdapterId)) {
      Hive.registerAdapter(TaskModelAdapter());
    }

    // -------------------------------------------------------------------------
    // Box opening
    // -------------------------------------------------------------------------
    var goalsBox = await Hive.openBox<GoalModel>(goalBoxName);
    var milestonesBox = await Hive.openBox<MilestoneModel>(milestoneBoxName);
    var tasksBox = await Hive.openBox<TaskModel>(taskBoxName);
    
    // Open view preferences box (stores user view field visibility settings)
    await Hive.openBox(viewPreferencesBoxName);
    
    // Open filter preferences box (stores user filter settings)
    await Hive.openBox(filterPreferencesBoxName);

    // // -------------------------------------------------------------------------
    // // Debug print section (for developer visibility)
    // // -------------------------------------------------------------------------
    // print('\n========== Hive Boxes Initialized ==========');

    // // ---- Goals Box ----
    // print('\n Goals Box (${goalsBox.length} entries)');
    // if (goalsBox.isEmpty) {
    //   print('  (empty)');
    // } else {
    //   for (var key in goalsBox.keys) {
    //     final goal = goalsBox.get(key);
    //     print('  ▶ Key: $key');
    //     print('    • Name       : ${goal?.name}');
    //     print('    • Description: ${goal?.description}');
    //     print('    • TargetDate : ${goal?.targetDate}');
    //     print('    • Context    : ${goal?.context}');
    //     print('    • Completed  : ${goal?.isCompleted}');
    //   }
    // }

    // // ---- Milestones Box ----
    // print('\n Milestones Box (${milestonesBox.length} entries)');
    // if (milestonesBox.isEmpty) {
    //   print('  (empty)');
    // } else {
    //   for (var key in milestonesBox.keys) {
    //     final ms = milestonesBox.get(key);
    //     print('  ▶ Key: $key');
    //     print('    • Name         : ${ms?.name}');
    //     print('    • Description  : ${ms?.description}');
    //     print('    • PlannedValue : ${ms?.plannedValue}');
    //     print('    • ActualValue  : ${ms?.actualValue}');
    //     print('    • TargetDate   : ${ms?.targetDate}');
    //     print('    • GoalId       : ${ms?.goalId}');
    //   }
    // }

    // // ---- Tasks Box ----
    // print('\n Tasks Box (${tasksBox.length} entries)');
    // if (tasksBox.isEmpty) {
    //   print('  (empty)');
    // } else {
    //   for (var key in tasksBox.keys) {
    //     final task = tasksBox.get(key);
    //     print('  ▶ Key: $key');
    //     print('    • Name        : ${task?.name}');
    //     print('    • TargetDate  : ${task?.targetDate}');
    //     print('    • MilestoneId : ${task?.milestoneId}');
    //     print('    • GoalId      : ${task?.goalId}');
    //     print('    • Status      : ${task?.status}');
    //   }
    // }

    // print('===========================================\n');

    return HiveBoxes(
      goalsBox: goalsBox,
      milestonesBox: milestonesBox,
      tasksBox: tasksBox,
    );
  }
}

/// Simple container class holding all opened Hive boxes.
///
/// Returned by [HiveInitializer.initialize] for easy dependency injection.
///
/// Example usage:
/// ```dart
/// final boxes = await HiveInitializer.initialize();
/// final goalBox = boxes.goalsBox;
/// final milestoneBox = boxes.milestonesBox;
/// final taskBox = boxes.tasksBox;
/// ```
class HiveBoxes {
  final Box<GoalModel> goalsBox;
  final Box<MilestoneModel> milestonesBox;
  final Box<TaskModel> tasksBox;

  HiveBoxes({
    required this.goalsBox,
    required this.milestonesBox,
    required this.tasksBox,
  });
}
